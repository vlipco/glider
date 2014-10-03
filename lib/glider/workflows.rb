class Glider::Component

    attr_reader :completed_event, :control

    class << self # all the following are class methods

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
            :request_cancel_external_workflow_execution_initiated ]

        def workflows
          @workflows ||= []
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
                ProcessManager.register_worker self.to_s, loop_block_for_workflow(workflow_type)
            end
        end
        
        private

        # used to determine if a :decised_task_started event should be renamed to :workflow_execution_started
        # when there are no previous decisions. This is because there's no special event name for this case.
        def has_previous_decisions?(workflow_execution)
            workflow_execution.history_events.each do |event|
                event_type = ActiveSupport::Inflector.underscore(event.event_type).to_sym
                return true if event_type == :decision_task_completed
            end
            return false
        end

        def decider_data_of(event_name, event)
            data = 	case event_name
                when :workflow_execution_started; begin event.attributes.input rescue {} end
                when :workflow_execution_signaled; begin event.attributes.input rescue {} end
                when :activity_task_completed; begin event.attributes.result rescue {} end
                when :activity_task_failed; begin event.attributes.reason rescue {} end
                else
                    begin
                        event.attributes.result
                    rescue
                        signature ="data={} event=#{event_name} attributes=#{event.attributes.to_h}"
                        Glider.logger.debug "no input or result in event #{signature}" and nil
                    end
                end
            begin # try to parse data as JSON
              return ActiveSupport::HashWithIndifferentAccess.new JSON.parse(data)
            rescue JSON::ParserError
              return data
            end
        end

        # inflects timeouts and activity task completed events into snake case
        def activity_name_for(task, event)
            # taken from SimplerWorkflow
            completed_event = completed_event_for(task, event)
            activity_name = completed_event.attributes.activity_type.name
            inflected_name = ActiveSupport::Inflector.underscore activity_name
        end

       # given one event of task execution being completed, find the information of the event
       # where it was scheduled. This is useful to know what activity was completed.
        def completed_event_for(task, event)
            task.workflow_execution.events.reverse_order.find do |e|
                begin
                  e.id == event.attributes.scheduled_event_id
                rescue ArgumentError
                  e.id == event.attributes.started_event_id
                end
            end
        rescue ArgumentError # is this in case there aren't previous events?
            nil
        end

        def control_for_completed_event(event)
            event.attributes.control
        rescue ArgumentError # if there's no control
            nil
        end

        def process_decision_task(workflow_type, task)
            workflow_id = task.workflow_execution.workflow_id
            task.new_events.each do |event|
                event_name = ActiveSupport::Inflector.underscore(event.event_type).to_sym
                # given the event name, determine if an instance of the workflow should be called
                # this happens because some events are not directly related to the need of an action on our side
                # but are instead normal part of SWF's detailed trail of the execution
                if MUTED_EVENTS.include? event_name
                    msg = "Skipping decider call event=#{event_name} workflow_id=#{task.workflow_execution.workflow_id}"
                    Glider.logger.debug(msg) and return true
                else
                    completed_event = completed_event_for(task, event)
                    control = completed_event ? control_for_completed_event(completed_event) : nil
                    target_instance = self.new task, event, completed_event, control
                    data = decider_data_of event_name, event
                    event_name = case event_name # handle convenience method event_name renaming, if applicable
                        when :workflow_execution_signaled; "#{event.attributes.signal_name}_signal"
                        when :activity_task_completed; "#{activity_name_for(task, event)}_activity_completed"
                        when :activity_task_failed; "#{activity_name_for(task, event)}_activity_failed"
                        when :activity_task_timed_out; "#{activity_name_for(task, event)}_activity_timed_out"
                        else event_name
                    end.to_sym
                    signature = "event_name=#{event_name} workflow=#{workflow_type.name} workflow_id=#{workflow_id}"
                    Glider.logger.info signature
                    target_instance.send workflow_type.name, event_name, event, data # execute the decider's instance
                    decisions = task.instance_eval {@decisions} # get the decisions from the
                    if decisions.length == 0 && !task.responded? # ensure that a decision (next step) was made
                        Glider.logger.warn "No decision was made #{signature}"
                    else
                        Glider.logger.debug decisions
                    end
                end
            end
        end

        def loop_block_for_workflow(workflow_type)
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
                              process_decision_task workflow_type, decision_task
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

  end
end