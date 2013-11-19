# isolates the common needed tasks of other elemtns

module Glider

	module Component

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

		# array of workers, one for each workflow type
		def build_workflows_workers
			workflows.map do |workflow_type|
				target_method = self.method(workflow_type.name)
				Proc.new do
					$logger.info "Startig worker for #{workflow_type.name} (class: #{self})"
					loop do
						#target_method.bind self
						target_method.call "TEST!"
						$logger.info "Polling #{workflow_type.name}"
						domain.decision_tasks.poll workflow_type.name do |task|
							$logger.info "Processing task #{task}"
							task.new_events.each do |event| 
								$logger.info "Processing #{event.event_type}"
								target_method.call event.event_type
							end
						end
					end
				end
			end
		end

	end

end