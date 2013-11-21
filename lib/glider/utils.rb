module Glider

	def Glider.execute(domain_name, workflow_name, version, input)
		swf = AWS::SimpleWorkflow.new
		domain = swf.domains[domain_name.to_s]
		domain.workflow_types[workflow_name.to_s, version].start_execution input: input, task_start_to_close_timeout: 5
	end

	def Glider.signal(domain_name, workflow_id, signal, options={})
		
	end
end