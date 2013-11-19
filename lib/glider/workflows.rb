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
						:decision_task_scheduled

					$logger.info "Processing #{event_name}"
					return true
				else
					$logger.info "Skipping call for event #{event_name}"
					return false
				end
				# possible events
		#WorkflowExecutionCompleted
		#ActivityTaskCompleted
		#ActivityTaskStarted
		#ActivityTaskScheduled
		#DecisionTaskCompleted
		#DecisionTaskStarted
		#DecisionTaskScheduled
		#WorkflowExecutionStarted
					
			end

			def loop_block_for_workflow(workflow_type)
				Proc.new do
					$logger.info "Startig worker for #{workflow_type.name} (class: #{self})"
					loop do
						#target_method.bind self
						target_method = self.new.method(workflow_type.name)
						target_method.call "TEST!"
						$logger.info "Polling #{workflow_type.name}"
						domain.decision_tasks.poll workflow_type.name do |task|
							$logger.info "Processing task #{task}"
							task.new_events.each do |event| 
								event_name = ActiveSupport::Inflector.underscore(event.event_type).to_sym
								#binding.pry
								target_method.call event_name if should_call_workflow_target? event_name
							end
						end
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