# isolates the common needed tasks of other elemtns

module Glider

	module Component

		def swf
			@swf ||= AWS::SimpleWorkflow.new
		end

		def workers(workers_count=nil)
			workers_count ? @workers = workers_count : @workers
		end

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

		# tracks forks/threads started by this
		def children
			@children ||= []
		end

		def waitall
			children.each{|t| t.join} # Wait until threads finish
		end

		def start_workers
			puts "Starting workers for #{activities} and #{workflows}"
			build_workflows_workers.each do |workflow_worker|
				children << Thread.new do
					workflow_worker.call
				end
			end
			waitall
		end

		def exit
			start_execution(name, version, input=nil)
			domain.workflow_types[name.to_s, version].start_execution input: input
		end

	end

end