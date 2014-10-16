# isolates the common needed tasks of other elemtns

module Glider

    class Component

        attr_reader :task, :workflow_execution, :workflow_name, :event

        def initialize(swf_task, swf_event=nil)
            @task = swf_task
            @workflow_execution = task.workflow_execution
            @workflow_name = workflow_execution.workflow_type.name
            if task.class == AWS::SimpleWorkflow::DecisionTask
                raise "Initializing with a decision task also requires the event argument" unless swf_event
                Glider.logger.debug "Creating component instance to handle decision task"
                @event = swf_event
            elsif AWS::SimpleWorkflow::ActivityTask
                Glider.logger.debug "Creating component instance to handle an activity task"
            else
                raise "Unknown activity type given during initialization"
            end
        end
        
        def process
            if task.class == AWS::SimpleWorkflow::DecisionTask
                process_decision_event
            else AWS::SimpleWorkflow::ActivityTask
                perform_activity_work
            end
        end

        private

        def perform_activity_work
            begin
                result = send task.activity_type.name, task.input
                unless task.responded?
                    Glider.logger.info "Executing #{task.signature}"
                    task.complete! result: result.to_s
                end
            rescue AWS::SimpleWorkflow::ActivityTask::CancelRequestedError
                activity_task.cancel! # cleanup after ourselves if the order's been given
            rescue Exception => e
                task.fail! reason: 'uncaught_exception', details: e
            end
        end
        
        def process_decision_event
            Glider.logger.info "Processing #{event.signature}"
            begin
                send workflow_name, event.name, event.decision_data
                if task.resolved? # ensure that a decision (next step) was made
                    Glider.logger.debug decisions
                else
                    Glider.logger.warn "No decision was made #{event.signature}"
                end
            rescue Exception => e
                task.fail_workflow_execution reason: 'uncaught_exception', details: e
            end
        end

    end

end