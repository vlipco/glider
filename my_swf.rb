require_relative 'shared_boot'

class MySWF < Glider::Component

	workers 1
	domain :glider_test

	#register_activity :hello_world, '1.1'
	register_workflow :say_hi, '1.1'#, initial_activity: [:settle, '1.1']

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
		when :workflow_execution_started
			$logger.info "say_hi scheduled hello_world"
			task.schedule_activity_task({name: 'hello_world', version: '1.1'})
		when :redirection_completed_signal
			data
		when :decision_task_started
			raise "I should never happen!"
			#task.complete!
		when :activity_task_completed
			task.complete_workflow_execution result: data
			task.complete! # NOT OPTIONAL
		else
			$logger.warn "Completing task for #{event_name}"
			task.complete!
			# TODO perform some task
		end
	end
	
	start_workers

end