require_relative 'shared_boot'

class MySWF < Glider::Component

	workers 1
	domain :glider_test

	register_activity :hello_world, '1.0'
	register_workflow :say_hi, '1.0'#, initial_activity: [:settle, '1.0']



	def hello_world(input)
		$logger.info "Executing hello_world. Input: #{input}. Returning current time"
		Time.now.to_s
	end


	def say_hi(input)
		$logger.info "====> Executing say_hi. Input: #{input}. #{event.event_type}"
		# TODO perform some task
	end

	# possible events
	#WorkflowExecutionCompleted
	#ActivityTaskCompleted
	#ActivityTaskStarted
	#ActivityTaskScheduled
	#DecisionTaskCompleted
	#DecisionTaskStarted
	#DecisionTaskScheduled
	#WorkflowExecutionStarted

	#def say_hi(event_name, data)
	#	case event_name
	#	when :workflow_execution_started
	#		data # input event.attributes.input
	#	else
	#		case event_name
	#		when :completed_settlement
	#			data # resultado de settlement event.attributes.result
	#			
	#	end
	#end
	
end

#binding.pry

MySWF.start_workers
#execution = MySWF.start_execution :say_hi, '1.0', "ALOHA"
#$logger.info "#{execution.status} id: #{execution.workflow_id}"

