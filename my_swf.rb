require_relative 'shared_boot'

class MySWF

	extend ::Glider::Component

	workers 1
	domain :glider_test

	register_activity :hello_world, '1.0'
	register_workflow :say_hi, '1.0'



	def self.hello_world(input)
		$logger.info "Executing hello_world. Input: #{input}. Returning current time"
		Time.now.to_s
	end


	def self.say_hi(input)
		$logger.info "Executing say_hi. Input: #{input}."
		# TODO perform some task
	end
	
end

#binding.pry

MySWF.start_workers
#execution = MySWF.start_execution :say_hi, '1.0', "ALOHA"
#$logger.info "#{execution.status} id: #{execution.workflow_id}"

