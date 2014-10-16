module Glider
    class Component
        class << self
            
            def start_all_pollers_and_block
                all_spawns = []
                descendants.each do |child|
                    Glider.logger.info "Starting pollers of #{child}"
                    all_spawns << child.start_pollers
                end
                all_spawns.flatten!
                Glider.logger.debug "Waiting for #{all_spawns.length} spawned processes"
                Spawnling.wait all_spawns
            end
            
            def descendants
                ObjectSpace.each_object(Class).select { |klass| klass < self }
            end

            def before_polling(&block)
                @before_polling_hook = block
            end

            def after_polling(&block)
                @after_polling_hook = block
            end

            def register_workflow(name, version, options={})
                options = WORKFLOW_DEFAULTS.merge({default_task_list: "#{name}-#{version}"}).merge options
                begin # try to register
                    workflow_type = domain.workflow_types.create name.to_s, version.to_s, options
                rescue AWS::SimpleWorkflow::Errors::TypeAlreadyExistsFault # if already registered
                    workflow_type = domain.workflow_types[name.to_s, version.to_s]
                end
                pollers << {
                    block: Proc.new { loop { workflow_decider_cycle(workflow_type) } },
                    name: workflow_type.name
                }
            end
            
            def register_activity(name, version, options={})
                options = ACTIVITY_DEFAULTS.merge({default_task_list: "#{name}-#{version}"}).merge options
                begin
                    activity_type = domain.activity_types.create name.to_s, version.to_s, options
                rescue AWS::SimpleWorkflow::Errors::TypeAlreadyExistsFault # already registered
                    activity_type = domain.activity_types[name.to_s, version.to_s]
                end
                pollers << {
                    block: Proc.new { loop { acitvity_worker_cycle(activity_type) } },
                    name: activity_type.name
                }
            end

            def domain(domain_name=nil, retention_period: 10) # both setter and getter
                if domain_name
                    begin
                        @domain = Glider.swf.domains[domain_name.to_s]
                        @domain.status
                    rescue AWS::SimpleWorkflow::Errors::UnknownResourceFault => e
                        # create it if necessary
                        @domain = Glider.swf.domains.create(domain_name.to_s, retention_period)
                    end
                else
                    @domain
                end
            end
            
                        
            private

            def pollers
                @pollers ||= []
            end
        

        end
    end
end