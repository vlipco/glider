# isolates the common needed tasks of other elemtns

module Glider

	class Component

		

		class << self
			def workflows
				@workflows ||= []
			end

			def register_workflow(name, version, options={})

				default_options = {
					:default_task_list => name.to_s,
					:default_child_policy => :request_cancel,
					:default_task_start_to_close_timeout => 10,
					:default_execution_start_to_close_timeout => 60
				}
				options = default_options.merge options
				begin
					workflow_type = domain.workflow_types.create name.to_s, version, options
				rescue AWS::SimpleWorkflow::Errors::TypeAlreadyExistsFault
					# already registered
					workflow_type = domain.workflow_types[name.to_s, version]
				end
				workflows << workflow_type
			end

			# let's us determine if :decised_task_started should be called :workflow_execution_started
            def has_previous_decisions?(workflow_execution)
                    workflow_execution.history_events.each do |event|
                            event_type = ActiveSupport::Inflector.underscore(event.event_type).to_sym
                            return true if event_type == :decision_task_completed
                    end
                    return false
            end

			def should_call_workflow_target?(event_name, workflow_execution)
				case event_name
				when 	:activity_task_scheduled,
						:activity_task_started,
						:decision_task_scheduled,
						:decision_task_started,
						:decision_task_completed,
						:marker_recorded,
						:timer_started,
						:start_child_workflow_execution_initiated,
						:start_child_workflow_execution_started,
						:signal_external_workflow_execution_initiated,
						:request_cancel_external_workflow_execution_initiated

					$logger.debug "Skipping decider call event=#{event_name} workflow_id=#{workflow_execution.workflow_id}"
					return false
				else
					return true
				end
			end

			def workflow_data_for(event_name, event)
				case event_name
				when :workflow_execution_started #:decision_task_scheduled
					event.attributes.input
				when :workflow_execution_signaled
					begin event.attributes.input rescue nil end
				when :activity_task_completed
					begin event.attributes.result rescue nil end
				else
					begin 
						event.attributes.result
					rescue
						$logger.debug "no input or result in event, data will be nil event=#{event_name} attributes=#{event.attributes.to_h}"
						nil
					end
				end 
			end

			def process_decision_task(workflow_type, task)
				$logger.info "\nProcessing decision task workflow_id=#{task.workflow_execution.workflow_id}"
				task.new_events.each do |event| 
					event_name = ActiveSupport::Inflector.underscore(event.event_type).to_sym
					if should_call_workflow_target? event_name, task.workflow_execution
					 	target_instance = self.new task, event
					 	data = workflow_data_for(event_name, event)
					 	# convert signals to event names!
					 	if event_name == :workflow_execution_signaled
					 		event_name = "#{event.attributes.signal_name}_signal"
						end
						target_instance.send workflow_type.name, event_name, data

						# ensure proper response was given (aka a decision taken)
						decisions = task.instance_eval {@decisions}
						$logger.debug decisions
						if decisions.length == 0 && !task.responded?
							# the decider didn't add any decision
							# force failure to avoid stalled executions in the domain
							binding.pry
							#raise "No decision for #{event_name}"
							task.complete!
							task.fail_workflow_execution reason: "UNHANDLED_DECISION"
							$logger.error "workflow #{workflow_type.name} didn't made any decisions for workflow_id=#{task.workflow_execution.workflow_id} failing execution"
						end
					end
				end
			end

			def loop_block_for_workflow(workflow_type)
				Proc.new do
					$logger.info "Startig worker for #{workflow_type.name} (class: #{self})"
					domain.decision_tasks.poll workflow_type.name do |decision_task|
						process_decision_task workflow_type, decision_task
					end
				end
			end

			# array of workers, one for each workflow type
			def build_workflows_workers
				workflows.map do |workflow_type|
					loop_block_for_workflow workflow_type
				end
			end
		end

	end

end