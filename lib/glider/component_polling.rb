module Glider
    class Component
        class << self

            def start_pollers
                spawns = []
                pollers.each_with_index do |poller, index|
                    #process_name = "#{$0}.#{index}-#{poller[:name]}"
                    spawns << Spawnling.new(method: :thread) do
                        poller[:block].call
                    end
                end
                return spawns
            end

            private
    
            def acitvity_worker_cycle(type)
                @before_polling_hook.call type.name if @before_polling_hook
                task_list = "#{type.name}-#{type.version}"
                Glider.logger.debug "Polling for activity task for #{type.name} on list=#{task_list}"
                domain.activity_tasks.poll_for_single_task task_list do |activity_task|
                    Glider.logger.debug "Activity task obtained for #{type.name} activity"
                    #TODO task_lock! do
                        handler = self.new activity_task
                        Glider.logger.debug "Triggering handler for #{type.name}"
                        result = handler.process
                        Glider.logger.debug "#{type.name} work completed, sending result"
                        activity_task.complete! result: result.to_s unless activity_task.responded?
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
                task_list = "#{type.name}-#{type.version}"
                Glider.logger.debug "Polling for decision task for workflow #{type.name} on list=#{task_list}"
                domain.decision_tasks.poll_for_single_task task_list do |decision_task|
                    #task_lock! do
                        Glider.logger.debug "Decision task obtained for workflow #{type.name}, processing new events"
                        decision_task.new_events.each do |event|
                            if event.muted?
                                Glider.logger.debug "Skipping decider call #{event.signature}"
                                next false
                            end
                            
                            handler = self.new(decision_task, event)
                            #binding.pry
                            Glider.logger.debug "Triggering handler for #{event.signature}"
                            handler.process
                            Glider.logger.debug "Processing completed #{event.signature}"
                        end
                        #Glider.logger.debug "%%%%%%%%%%%%%%%% Closing decision task"
                        #decision_task.complete! this should happen automatically
                    #end
                end
                @after_polling_hook.call type.name if @after_polling_hook
            rescue AWS::SimpleWorkflow::Errors::UnknownResourceFault
                Glider.logger.error "An action an expired task was sent, maybe the decision timed out"
            #rescue Exception => e
            #    # since we don't want to loop to stop (think of it as monitoring), we yield a specific exception
            #    # and a special alert message that can be monitored in the logs
            #    Glider.logger.error "Rescuing unexpected exception in decider to recover worker: #{e}"
            #    Glider.logger.fatal "HUMAN_INTERVENTION_REQUIRED"
            end

        end
    end # class end
end # module end
