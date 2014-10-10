# isolates the common needed tasks of other elemtns

module Glider

    class Component

        attr_reader :task, :workflow_execution, :workflow_name, :event, :event_name, :event_data

        def initialize(swf_task, swf_event)
            @task = swf_task
            @workflow_execution = task.workflow_execution
            @workflow_name = workflow_execution.workflow_type.name
            case task.class
                when AWS::SimpleWorkflow::DecisionTask
                    Glider.logger.debug "Creating component instance to handle decision task"
                    @event = swf_event
                    @event_name = event.name
                    @event_data = event.decision_data
                when AWS::SimpleWorkflow::ActivityTask
                    Glider.logger.debug "Creating component instance to handle an activity task"
                else
                    raise "Unknown activity type given during initialization"
            end
        end
        
        def process!
            if task.class == AWS::SimpleWorkflow::DecisionTask
                process_decision_event!
            else AWS::SimpleWorkflow::ActivityTask
                # TODO
            end
        end
        
        def process_decision_event!
            Glider.logger.info "Processing #{event.signature}"
            send workflow_name
            if task.resolved? # ensure that a decision (next step) was made
                Glider.logger.debug decisions
            else
                Glider.logger.warn "No decision was made #{signature}"
            end
        end


        def activity(name, version)
            {name: name.to_s, version: version.to_s}
        end


        class << self

            attr_reader :before_polling_hook, :after_polling_hook

            # registed a polling hook
            def before_polling(&block)
                @before_polling_hook = block
            end

            # registed a polling hook
            def after_polling(&block)
                @after_polling_hook = block
            end

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

            def register_signal_handlers
                if ProcessManager.use_forking
                    Signal.trap('USR1') {graceful_exit}
                end
            end

            def swf
                self == Glider::Component ? @swf ||= AWS::SimpleWorkflow.new : Component::swf
            end

            # both setter and getter
            def workers(workers_count=nil)
                workers_count ? @workers = workers_count : @workers ||= 1
            end

            # both setter and getter
            def domain(domain_name=nil, retention_period: 10)
                if domain_name
                    begin
                        @domain = Component::swf.domains[domain_name.to_s]
                        @domain.status
                    rescue AWS::SimpleWorkflow::Errors::UnknownResourceFault => e
                        # create it if necessary
                        @domain = Component::swf.domains.create(domain_name.to_s, retention_period)
                    end
                else
                    @domain
                end
            end

        end

    end

end