module Glider

	def Glider.logger
		$logger ||= Logger.new STDOUT
	end

	def Glider.execute(domain_name, workflow_name, version, options={})
		swf = AWS::SimpleWorkflow.new
		domain = swf.domains[domain_name.to_s]
		options = { task_start_to_close_timeout: 5 }.merge(options)
		domain.workflow_types[workflow_name.to_s, version.to_s].start_execution options
	end

	def Glider.signal(domain_name, workflow_id, signal_name, options={})
		swf = AWS::SimpleWorkflow.new
		domain = swf.domains[domain_name.to_s]
		workflow_execution = domain.workflow_executions.with_workflow_id(workflow_id).with_status(:open).first
		workflow_execution.signal signal_name.to_s, options
	end
end