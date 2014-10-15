require_relative 'boot'

class MySWF < Glider::Component

	workers 1
	domain :gt3

	register_workflow :say_hi, '1.5'

	before_polling do |workflow_name|
		Glider::logger.info "POLLING #{workflow_name}"
	end

	after_polling do |workflow_name|
		Glider::logger.info "POLLING OK #{workflow_name}"
	end

	def say_hi(event_name, event, data)
		case event_name
		when :workflow_execution_started, :hello_world_activity_timed_out
			task.schedule_activity_task activity(:hello_world, 1.5), input: data.to_json
		when :test_signal
			# do what?
		when :hello_world_activity_failed
			$logger.error "EXPECTED ERROR!"
		when :hello_world_activity_completed
			task.complete_workflow_execution result: data
		end
	end
end

Glider::ProcessManager.start_workers from_class: MySWF