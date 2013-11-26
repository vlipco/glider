require_relative 'shared_boot'

class MySWF < Glider::Component

	workers 10
	domain :gt3

	register_activity :hello_world, '1.5'

	def hello_world(input)
		$logger.warn "Executing hello_world."
		sleep 2
		$logger.warn "Completed hello_world."
		"Hello!"
	end

end

Glider::ProcessManager.start_workers