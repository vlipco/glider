require_relative 'shared_boot'

class MySWF < Glider::Component

	workers 1
	domain :glider_test

	register_activity :hello_world, '1.0'
	register_workflow :say_hi, '1.0'#, initial_activity: [:settle, '1.0']

	def hello_world(input)
		task.record_heartbeat! :details => '25%'
		$logger.info "Executing hello_world. Input: #{input}. Returning current time"
		task.record_heartbeat! :details => '50%'
		Time.now.to_s
	end

	def say_hi(event_name, data)
		$logger.info "say_hi event=#{event_name} data=#{data}"
		# TODO :workflow_execution_started, how to handle??
		case event_name
		when :decision_task_started
			$logger.info "say_hi scheduled hello_world"
			task.schedule_activity_task({name: 'hello_world', version: '1.0'})

		when :activity_task_completed
			task.complete_workflow_execution result: data
			task.complete!
		else
			$logger.warn "say_hi event=#{event_name} data=#{data}"
			# TODO perform some task
		end
	end
	
	start_workers

end