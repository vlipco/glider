# Monkey Patch a class to allow access to the @decisions variable
class AWS::SimpleWorkflow::DecisionTask; attr_reader :decisions; end

class Glider::Component

    attr_reader :completed_event, :control

    class << self # all the following are class methods

        def workflows
          @workflows ||= []
        end
        
        
        def activity(name, version)
            {name: name.to_s, version: version.to_s}
        end


        def register_workflow(name, version, options={})
            options = {
                :default_task_list => name.to_s,
                :default_child_policy => :request_cancel,
                :default_task_start_to_close_timeout => 10, # decider timeout
                :default_execution_start_to_close_timeout => 120
            }.merge options
            begin # try to register
                workflow_type = domain.workflow_types.create name.to_s, version.to_s, options
            rescue AWS::SimpleWorkflow::Errors::TypeAlreadyExistsFault # if already registered
                workflow_type = domain.workflow_types[name.to_s, version.to_s]
            end
            workers.times do
                # we store the worker scoped to this class so that we can start workers from class
                ProcessManager.register_worker self.to_s, workflow_poller_for(workflow_type)
            end
        end

        def workflow_poller_for(workflow_type)
            Proc.new do
                if Glider::ProcessManager.use_forking
                    # set the process name if forking, useful for readable `ps -aux` output
                    $0 = "ruby #{workflow_type.name}-#{workflow_type.version}"
                end
                register_signal_handlers
                Glider.logger.info "Startig worker for #{workflow_type.name} (pid #{Process.pid})"
                loop do
                    begin
                        Glider.logger.debug "Polling for task for #{workflow_type.name}"
                        before_polling_hook.call workflow_type.name if before_polling_hook
                        domain.decision_tasks.poll_for_single_task workflow_type.name do |decision_task|
                            task_lock! do
                                decision_task.new_events.each do |event|
                                    if event.muted?
                                        Glider.logger.debug "Skipping decider call #{event.signature}"
                                        return false
                                    else
                                        target = self.new task, event
                                        target.process!
                                    end
                                end
                                decision_task.complete!
                            end
                        end
                        after_polling_hook.call workflow_type.name if after_polling_hook
                    rescue Glider::ProcessManager::ThreatExitSignal
                        execute_exit
                    rescue AWS::SimpleWorkflow::Errors::UnknownResourceFault
                        $logger.error "Sent an action to an expired decision, was the decision timeout exceeded?"
                    end
                end
            end
        end

    end # class methods
end # class definition