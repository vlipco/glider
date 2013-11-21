require_relative 'shared_boot'

class MySWF < Glider::Component

	workers 1
	domain :glider_test

	register_activity :hello_world, '1.0'
	register_workflow :say_hi, '1.0'#, initial_activity: [:settle, '1.0']

	def hello_world(input)
		task.record_heartbeat! :details => '25%'
		$logger.info "Executing hello_world. Input: #{input}."
		task.record_heartbeat! :details => '50%'
		"Hello!"
	end

	def say_hi(event_name, event, data)
		$logger.info "say_hi event=#{event_name} data=#{data}"
		# TODO :workflow_execution_started, how to handle??
		case event_name
		when :workflow_execution_started
			$logger.info "say_hi scheduled hello_world"
			task.schedule_activity_task({name: 'hello_world', version: '1.0'})
		when :redirection_completed_signal
			data
		when :activity_task_completed
			task.complete_workflow_execution result: data
			task.complete! # NOT OPTIONAL
		else
			$logger.warn "Completing task for #{event_name}"
			
			task.complete! unless task.responded?
			
			# TODO perform some task
		end
	end
	
	start_workers

end