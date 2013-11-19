# isolates the common needed tasks of other elemtns

module Glider

	module Component
		
		def activities
			@activities ||= []
		end

		def register_activity(name, version, options={})
			default_options = {
				:default_task_list => name.to_s,
				:default_task_heartbeat_timeout => 900,
				:default_task_schedule_to_start_timeout => 60,
				:default_task_schedule_to_close_timeout => 3660,
				:default_task_start_to_close_timeout => 3600
			}

			options = default_options.merge options

			begin
				activity_type = domain.activity_types.create name.to_s, version, options
			rescue AWS::SimpleWorkflow::Errors::TypeAlreadyExistsFault
				# already registered
				activity_type = domain.activity_types[name.to_s, version]
			end
			activities << activity_type
		end

	end

end