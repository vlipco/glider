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
					:default_task_start_to_close_timeout => 3600,
					:default_execution_start_to_close_timeout => 24 * 3600
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

			def should_call_workflow_target?(event_name)
				case event_name
				when 	:activity_task_completed,
						:workflow_execution_started,
						:workflow_execution_signaled #,
						#:decision_task_scheduled

					$logger.info "Calling target decider for #{event_name}"
					return true
				else
					$logger.debug "Skipping call for event #{event_name}"
					return false
				end
				# possible events
		#WorkflowExecutionCompleted
		#ActivityTaskCompleted
		#ActivityTaskStarted
		#ActivityTaskScheduled
		#DecisionTaskCompleted
		#DecisionTaskStarted
		#decision_task_timed_out
		#DecisionTaskScheduled
		#WorkflowExecutionStarted
					
			end

			def workflow_data_for(event_name, event)
				case event_name
				when :workflow_execution_started #:decision_task_scheduled
					event.attributes.input
				when :activity_task_completed
					event.attributes.result
				when :workflow_execution_signaled
					begin event.attributes.input rescue nil end
				else
					raise "#{event_name} should ask for data"
				end 
			end

			def process_decision_task(workflow_type, task)
				$logger.info "Processing decision task workflow_id=#{task.workflow_execution.workflow_id}"
				task.new_events.each do |event| 
					event_name = ActiveSupport::Inflector.underscore(event.event_type).to_sym
					if should_call_workflow_target? event_name
					 	target_instance = self.new task, event
					 	data = workflow_data_for(event_name, event)
					 	# convert signals to event names!

					 	if event_name == :workflow_execution_signaled
					 		signal_name = event.attributes.signal_name
							event_name = signal_name == "decision_pending" ? 
											:workflow_execution_started : signal_name
						end
						target_instance.send workflow_type.name, event_name, data

						# TODO ensure continuity in execution aka something was scheduled
					end
				end
			end

			def loop_block_for_workflow(workflow_type)
				Proc.new do
					$logger.info "Startig worker for #{workflow_type.name} (class: #{self})"
					domain.decision_tasks.poll workflow_type.name do |decision_task|
						process_decision_task workflow_type, decision_task

						# task.complete! will be called by default
						# hence, we need to signal this wasn't responded
						# so that a new decision is scheduled
						decisions = decision_task.instance_eval {@decisions}
						$logger.debug decisions
						if decisions.length == 0
							# the decider didn't add any decision
							# force failure to avoid stalled executions in the domain
							decision_task.fail_workflow_execution reason: "UNHANDLED_DECISION"
							decision_task.complete!
							$logger.error "workflow #{workflow_type.name} didn't made any decisions for workflow_id=#{decision_task.workflow_execution.workflow_id} failing execution"
						end
						#	$logger.warn "Decision task wasn't manually completed. Signaling decision_pending workflow_id=#{#decision_task.workflow_execution.workflow_id}"
						#	decision_task.workflow_execution.signal "decision_pending"
						#end
							
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