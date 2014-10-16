module Glider

    EXECUTION_DEFAULTS = { task_start_to_close_timeout: 3 }
    
    WORKFLOW_DEFAULTS = {
        #:default_task_list => 'glider',
        :default_child_policy => :request_cancel,
        :default_task_start_to_close_timeout => 3, # decider timeout
        :default_execution_start_to_close_timeout => 10
    }
    
    ACTIVITY_DEFAULTS = {
        #:default_task_list => name.to_s,
        :default_task_schedule_to_start_timeout => 3,
        :default_task_start_to_close_timeout => 3,
        :default_task_schedule_to_close_timeout => 6,
        :default_task_heartbeat_timeout => :none
    }
    
    def Glider.swf
        @swf ||= AWS::SimpleWorkflow.new
    end

    def Glider.logger
        @logger ||=  Logger.new STDOUT
    end

    def Glider.logger=(new_logger)
        Spawnling.logger = new_logger # used in Spawnling
        @logger = new_logger
    end

    def Glider.execute(domain_name, workflow_name, version, options={})
        swf = AWS::SimpleWorkflow.new
        domain = swf.domains[domain_name.to_s]
        options = EXECUTION_DEFAULTS.merge({task_list: "#{workflow_name}-#{version}"}).merge(options)
        domain.workflow_types[workflow_name.to_s, version.to_s].start_execution options
    end

    def Glider.signal(domain_name, workflow_id, signal_name, options={})
        swf = AWS::SimpleWorkflow.new
        domain = swf.domains[domain_name.to_s]
        workflow_execution = domain.workflow_executions.with_workflow_id(workflow_id).with_status(:open).first
        raise AWS::SimpleWorkflow::Errors::UnknownResourceFault.new unless workflow_execution
        workflow_execution.signal signal_name.to_s, options
    end

end