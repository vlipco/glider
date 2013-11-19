require_relative 'shared_boot'

class Decider

	extend ::Glider::Component

	workers 1
	domain :glider_test

	register_workflow :say_hi, '1.0'

	def say_hi(input)
		$logger.info "Executing say_hi. Input: #{input}."
		# TODO perform some task
	end
end

Decider.start_workers

