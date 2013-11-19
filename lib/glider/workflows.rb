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

	end

end