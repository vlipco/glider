require_relative 'shared_boot'

class MySWF < Glider::Component

	workers 10
	domain :gt3

	register_workflow :say_hi, '1.5'

	def say_hi(event_name, event, data)
		case event_name
		when :workflow_execution_started, :hello_world_activity_timed_out
			act = {name: 'hello_world', version: '1.5'}
			task.schedule_activity_task act
		when :test_signal
			# do what?		
		when :hello_world_activity_completed
			task.complete_workflow_execution result: data
		end
	end
end

Glider::ProcessManager.start_workers