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
					:default_task_schedule_to_start_timeout => 10,
					:default_task_start_to_close_timeout => 60
				}

				options = default_options.merge options

				begin
					activity_type = domain.activity_types.create name.to_s, version, options
				rescue AWS::SimpleWorkflow::Errors::TypeAlreadyExistsFault
					# already registered
					activity_type = domain.activity_types[name.to_s, version]
				end
				workers.times do 
					ProcessManager.register_worker loop_block_for_activity(activity_type)
				end
			end



			def loop_block_for_activity(activity_type)
				Proc.new do
					signal_handling
					Glider.logger.info "Startig worker for #{activity_type.name} activity (pid #{Process.pid})"
					domain.activity_tasks.poll activity_type.name do |activity_task|
						task_lock! do
							begin
								target_instance = self.new activity_task
								activity_result = target_instance.send activity_type.name, activity_task.input
								activity_task.complete! result: activity_result.to_s
							rescue ActivityTask::CancelRequestedError
								# cleanup after ourselves
								activity_task.cancel!
							end
						end
					end
				end
			end


		end

	end

end