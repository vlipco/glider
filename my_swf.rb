require_relative 'shared_boot'

class MySWF < Glider::Component

	workers 4
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
		$logger.info "Making decision event=#{event_name} data=#{data}"
		case event_name
		when :workflow_execution_started
			$logger.info "Scheduling hello_world"
			task.schedule_activity_task({name: 'hello_world', version: '1.0'})
		when :test_signal
			$logger.info "Received test signal"
			task.complete!
		when :hello_world_activity_completed
			task.complete_workflow_execution result: data
			task.complete! # NOT OPTIONAL
		else
			$logger.warn "Completing task for unexpected #{event_name}"
			task.complete! unless task.responded?
		end
		sleep 5
		puts "COMPLETED!!"
	end
	
	

end

Glider::ProcessManager.start_workers