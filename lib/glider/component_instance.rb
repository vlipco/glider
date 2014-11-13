# isolates the common needed tasks of other elemtns

module Glider

    class Component

        attr_reader :task, :workflow_execution, :workflow_name, :event
        
        def activity(name, version)
            {name: name.to_s, version: version.to_s}
        end

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
                Glider.logger.error "Rescued unexpected exception on #{task.activity_type.name}: #{e}"
                e.backtrace.each {|trace| Glider.logger.error "  #{trace}" }
                task.fail! reason: 'uncaught_exception', details: e.class.to_s
            end
        end
        
        def process_decision_event
            Glider.logger.info "Processing #{event.signature}"
            begin
                send workflow_name, event.name, event.decision_data
                if task.decisions.length > 0 # ensure that a decision (next step) was made
                    Glider.logger.debug task.decisions
                else
                    Glider.logger.error "Failing workflow since no decision was made in response to #{event.signature}"
                    task.fail_workflow_execution reason: 'empty_decision', details: event.signature
                end
            rescue Exception => e
                Glider.logger.error "Rescued unexpected exception during decision of workflow=#{workflow_name}: #{e}"
                e.backtrace.each {|trace| Glider.logger.error "  #{trace}" }
                msg = "#{e} - #{e.backtrace.first}"
                Glider.logger.error "Failing workflow with details: #{msg}"
                task.fail_workflow_execution reason: 'uncaught_exception', details: msg
            end
        end

    end

end