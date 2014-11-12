# this file adds some convenience methods to aws-sdk classes to simplify
# workflow data extraction
module AWS
    class SimpleWorkflow
        
        # full implementation at:
        # https://github.com/aws/aws-sdk-ruby/blob/master/lib/aws/simple_workflow/workflow_execution.rb
        class WorkflowExecution
            
            # used to determine if a :decised_task_started event should be renamed to :workflow_execution_started
            # when there are no previous decisions. This is because there's no special event name for this case.
            def has_previous_decisions?
                history_events.each do |event|
                    return true if event.raw_name == :decision_task_completed
                end
                return false
            end
            
            def name
                workflow_type.name
            end
            
            alias_method :id, :workflow_id
            
            def signature
                "workflow=#{name} workflow_id=#{id}"
            end
        end

        class ActivityTask
            def signature
                "activity=#{activity_type.name} workflow_id=#{workflow_execution.id}"
            end
            
            alias_method :original_input, :input
            
            def input
                # try to parse data as JSON
                begin
                    return ActiveSupport::HashWithIndifferentAccess.new JSON.parse(original_input)
                rescue JSON::ParserError, TypeError
                    return original_input
                end
            end
        end

        # https://github.com/aws/aws-sdk-ruby/blob/master/lib/aws/simple_workflow/decision_task.rb
        class DecisionTask

            attr_reader :decisions
            
            alias_method :original_schedule_activity_task, :schedule_activity_task
            
            def schedule_activity_task(activity_type, options = {})
                # this only accepts hashes
                options = options.merge({task_list: "#{activity_type[:name]}-#{activity_type[:version]}"})
                original_schedule_activity_task activity_type, options
            end
            

        end

        # https://github.com/aws/aws-sdk-ruby/blob/master/lib/aws/simple_workflow/history_event.rb
        class HistoryEvent
            
            # name of the events that shouldn't trigger a call on a decider's instance
            MUTED_EVENTS = [
                :activity_task_scheduled,
                :activity_task_started,
                :decision_task_scheduled,
                :decision_task_started,
                :decision_task_completed,
                :marker_recorded,
                :timer_started,
                :start_child_workflow_execution_initiated,
                :start_child_workflow_execution_started,
                :signal_external_workflow_execution_initiated,
                :request_cancel_external_workflow_execution_initiated,
                :external_workflow_execution_signaled ]
                
            # TODO decide how to handle decision task timed out
            
            def ancestor
                workflow_execution.events.reverse_order.find do |e|
                    begin
                      e.id == attributes.scheduled_event_id
                    rescue ArgumentError
                      e.id == attributes.started_event_id
                    end
                end
            end
            
            def signature
                "event_name=#{name} #{workflow_execution.signature}"
            end
            
            def muted?
                MUTED_EVENTS.include? raw_name
            end

            def activity_name
                ActiveSupport::Inflector.underscore(ancestor.attributes.activity_type.name).to_sym
            end

            def control
                begin ancestor.attributes.control; rescue ArgumentError; nil; end
            end
            
            def raw_name
                ActiveSupport::Inflector.underscore(event_type).to_sym
            end

            # TODO convert time outs to replay of the last events!
            # TODO handle ScheduleActivityTaskFailed because activity doesn't exist
            def name
                case raw_name # handle convenience method event_name renaming, if applicable
                    when :workflow_execution_signaled; "#{attributes.signal_name}_signal"
                    when :activity_task_completed; "#{activity_name}_activity_completed"
                    when :activity_task_failed; "#{activity_name}_activity_failed"
                    when :activity_task_timed_out; "#{activity_name}_activity_timed_out"
                    else raw_name
                end.to_sym
            end

            def decision_data
                begin
                    data = case raw_name
                        when :workflow_execution_started; attributes.input
                        when :workflow_execution_signaled; attributes.input
                        when :activity_task_failed; attributes.reason
                        else attributes.result
                    end
                rescue
                    Glider.logger.debug "no input or result in event #{signature}"
                    data = nil
                end
                # try to parse data as JSON
                begin
                    return ActiveSupport::HashWithIndifferentAccess.new JSON.parse(data)
                rescue JSON::ParserError, TypeError
                    return data
                end
            end

        end
    end
end