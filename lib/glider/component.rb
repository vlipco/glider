# isolates the common needed tasks of other elemtns

module Glider

	class Component

		attr_reader :task, :event

		def initialize(task, event=nil)
			@task = task
			@event = event
		end


		class << self

			def task_lock!
				@in_task = true
				yield
			ensure
				@in_task = false
				Process.exit 0 if @time_to_exit # in case an exit signal was received during task processing
			end

			def graceful_exit
				if @in_task
					@time_to_exit = true
				else
					Process.exit 0
				end
			end

			def signal_handling
				Signal.trap('QUIT') do
					graceful_exit
				end

				Signal.trap('INT') do
					graceful_exit
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