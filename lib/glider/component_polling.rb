module Glider
    class Component
        class << self

            def start_pollers
                #Glider.logger.info "Startig poller for #{type.name}"
                #if swf_type_object.class == AWS::SimpleWorkflow::WorkflowType
                #    loop { workflow_decider_cycle }
                #else
                #    loop { acitvity_worker_cycle }
                #end
            end

            private
    
            def acitvity_worker_cycle(type)
                Glider.logger.debug "Polling for task for #{type.name}"
                @before_polling_hook.call type.name if @before_polling_hook
                domain.activity_tasks.poll_for_single_task(type.name) do |activity_task|
                    #TODO task_lock! do
                        self.new activity_task
                    #end
                end
                @after_polling_hook.call type.name if @after_polling_hook
            rescue AWS::SimpleWorkflow::Errors::UnknownResourceFault
                Glider.logger.error "An action an expired task was sent, maybe the execution timed out"
            rescue RuntimeError => e
                if e.to_s == "already responded"
                    # this error sometimes appears if failing and completing happen very close in time
                    # and SWF doesn't report correctly the responded? status
                    Glider.logger.warn "Ignoring already responded error."
                else
                    raise e
                end
            end
            
            def workflow_decider_cycle(type)
                Glider.logger.debug "Polling for task for #{workflow_type.name}"
                @before_polling_hook.call workflow_type.name if @before_polling_hook
                domain.decision_tasks.poll_for_single_task workflow_type.name do |decision_task|
                    task_lock! do
                        decision_task.new_events.each do |event|
                            if event.muted?
                                Glider.logger.debug "Skipping decider call #{event.signature}"
                                return false
                            end
                            self.new(task, event).process
                        end
                        decision_task.complete!
                    end
                end
                @after_polling_hook.call type.name if @after_polling_hook
            rescue AWS::SimpleWorkflow::Errors::UnknownResourceFault
                Glider.logger.error "An action an expired task was sent, maybe the decision timed out"
            end

        end
    end # class end
end # module end
