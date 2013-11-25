require_relative 'shared_boot'

class MySWF < Glider::Component

	workers 5
	domain :gt3

	register_activity :hello_world, '1.5'
	register_workflow :say_hi, '1.5'#, initial_activity: [:settle, '1.5']

	def hello_world(input)
		$logger.warn "Executing hello_world."
		sleep 2
		#puts "============ ACTIVITY COMPLETED!"
		$logger.warn "Completed hello_world."
		"Hello!"
	end

	def say_hi(event_name, event, data)
#		$logger.warn "      Making decision event=#{event_name} data=#{data}"
		#sleep 10
		case event_name
		when :workflow_execution_started, :hello_world_activity_timed_out
			#$logger.info "      Scheduling hello_world"
			act = {name: 'hello_world', version: '1.5'}
			task.schedule_activity_task act#, start_to_close_timeout: 2
		when :test_signal
			#$logger.info "      Received test signal"
			#task.complete!
		when :hello_world_activity_completed
			#$logger.info "======"
			task.complete_workflow_execution result: data
			#task.complete! # NOT OPTIONAL
		end
		#puts "DECISION COMPLETED!"
	end
	
	

end

Glider::ProcessManager.start_workers