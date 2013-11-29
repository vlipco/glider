# isolates the common needed tasks of other elemtns

module Glider

	class Component

		attr_reader :task, :event

		def initialize(task, event=nil)
			@task = task
			@event = event
		end

		def activity(name, version)
			{name: name.to_s, version: version.to_s}
		end


		class << self

			# handles the exit flag differently for forks and threads
			def time_to_exit
				ProcessManager.use_forking ? @time_to_exit : Thread.current[:time_to_exit]
			end

			def task_lock!
				#Glider.logger.info "=> Starting task: #{Thread.current[:x]}"
				Thread.current[:in_task] = true
				@in_task = true
				yield
			ensure
				@in_task = false
				Thread.current[:in_task] = false
				execute_exit if time_to_exit # in case an exit signal was received during task processing
			end

			def graceful_exit
				if ProcessManager.use_forking
					if @in_task
						@time_to_exit = true
					else
						execute_exit
					end
				else
					if Thread.current[:in_task]
						Thread.current[:time_to_exit] = true
					else
						execute_exit
					end
				end
			end

			def execute_exit
				if ProcessManager.use_forking
					Process.exit! 0
				else
					#puts "Killing #{Thread.current}"
					Thread.current.exit
				end
			end

			def signal_handling
				if ProcessManager.use_forking
					Signal.trap('USR1') {graceful_exit}
				end
			end

			def swf
				@swf ||= AWS::SimpleWorkflow.new
			end

			# both setter and getter
			def workers(workers_count=nil)
				workers_count ? @workers = workers_count : @workers ||= 1
			end

			# both setter and getter
			def domain(domain_name=nil, retention_period: 10)
				if domain_name
					begin
						@domain = swf.domains[domain_name.to_s]
						@domain.status
					rescue AWS::SimpleWorkflow::Errors::UnknownResourceFault => e
						# create it if necessary
						@domain = swf.domains.create(domain_name.to_s, retention_period)
					end
				else
					@domain
				end
			end

		end

	end

end