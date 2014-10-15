require_relative 'boot'

class MySWF < Glider::Component

	workers 10
	domain :gt3

	register_activity :hello_world, '1.5'

	def hello_world(input)
		#binding.pry
		#$logger.warn input[:message]
		$logger.warn "Executing hello_world."
		sleep 3
		task.fail! reason: "BECAUSE!" and task.fail! and return
		$logger.warn "Completed hello_world."
		"Hello!"
	end

end
#pry
Glider::ProcessManager.start_workers