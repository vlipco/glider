# isolates the common needed tasks of other elemtns

module Glider

	class Component

		attr_reader :task, :event

		def initialize(task, event=nil)
			@task = task
			@event = event
		end

		class << self
			def swf
				@swf ||= AWS::SimpleWorkflow.new
			end

			# both setter and getter
			def workers(workers_count=nil)
				workers_count ? @workers = workers_count : @workers
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

			# tracks forks/threads started as workers
			def children
				@children ||= []
			end

			def waitall
				children.each{|t| t.join} # Wait until threads finish
			end

			def start_workers
				activities_list = activities.map {|act| "#{act.name}-#{act.version}"}
				workflows_list = workflows.map {|wf| "#{wf.name}-#{wf.version}"}
				$logger.info "Starting workers for #{activities_list} and #{workflows_list}"
				all_workers = [build_workflows_workers, build_activities_workers].flatten
				all_workers.each do |workflow_worker|
					children << Thread.new do
						@workers.times {|i| workflow_worker.call}
					end
				end
				waitall
			end

		end

	end

end