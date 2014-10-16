module Glider
    class Component
        class << self

            def start_pollers
                spawns = []
                pollers.each_with_index do |poller, index|
                    process_name = "#{$0}.#{index}-#{poller[:name]}"
                    spawns << Spawnling.new(argv: process_name, kill: true, method: :fork) do
                        poller[:block].call
                    end
                end
                # wait for all N blocks of code to finish running (should never happen)
                Spawnling.wait spawns
            end

            private
    
            def acitvity_worker_cycle(type)
                @before_polling_hook.call type.name if @before_polling_hook
                Glider.logger.debug "Polling for activity task for #{type.name}"
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
                @before_polling_hook.call type.name if @before_polling_hook
                Glider.logger.debug "Polling for decision task for workflow #{type.name}"
                domain.decision_tasks.poll_for_single_task type.name do |decision_task|
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
