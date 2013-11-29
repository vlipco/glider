# isolates the common needed tasks of other elemtns

module Glider

	class Component
		class << self

			def activities
				@activities ||= []
			end

			def register_activity(name, version, options={})
				default_options = {
					:default_task_list => name.to_s,
					:default_task_schedule_to_start_timeout => :none,
					:default_task_start_to_close_timeout => 60,
					:default_task_schedule_to_close_timeout => :none,
					:default_task_heartbeat_timeout => :none

				}

				options = default_options.merge options

				begin
					activity_type = domain.activity_types.create name.to_s, version.to_s, options
				rescue AWS::SimpleWorkflow::Errors::TypeAlreadyExistsFault
					# already registered
					activity_type = domain.activity_types[name.to_s, version.to_s]
				end
				workers.times do 
					ProcessManager.register_worker loop_block_for_activity(activity_type)
				end
			end

			def process_input(input)
				if input.nil?
					nil
				else
					# try to parse input as json
					begin
						input = ActiveSupport::HashWithIndifferentAccess.new JSON.parse(input)
					rescue JSON::ParserError
						input
					end
				end
			end



			def loop_block_for_activity(activity_type)
				Proc.new do
					$0 = "ruby #{activity_type.name}-#{activity_type.version}"
					signal_handling
					Glider.logger.info "Startig worker for #{activity_type.name} activity (pid #{Process.pid})"
					loop do
						begin
							domain.activity_tasks.poll activity_type.name do |activity_task|
								task_lock! do
									begin
										workflow_id = activity_task.workflow_execution.workflow_id
										Glider.logger.info "Executing activity=#{activity_type.name} workflow_id=#{workflow_id}"
										target_instance = self.new activity_task
										input = process_input(activity_task.input)
										activity_result = target_instance.send activity_type.name, input
										 
										activity_task.complete! result: activity_result.to_s unless activity_task.responded?

									rescue AWS::SimpleWorkflow::ActivityTask::CancelRequestedError
										# cleanup after ourselves
										activity_task.cancel!
									end
								end
							end
						rescue AWS::SimpleWorkflow::Errors::UnknownResourceFault
							$logger.error "An action relating to an expired workflow was sent. Probably the activity took longer than the execution timeout span."
						rescue Glider::ProcessManager::ThreatExitSignal
							execute_exit
						rescue RuntimeError => e
							if e.to_s == "already responded"
								# this error sometimes appear if failing and completing happen very close in time and SWF doesn't report correctly the responded? status
								Glider.logger.warn "Ignoring already responded error."
							else
								raise e
							end
						end
					end
				end
			end


		end

	end

end