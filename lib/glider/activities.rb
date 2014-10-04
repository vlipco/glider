# isolates the common needed tasks of other elemtns

module Glider

    class Component
        class << self

            def activities
                @activities ||= []
            end

            def register_activity(name, version, options={})
                default_options = {
                    :default_task_list => name.to_s,
                    :default_task_schedule_to_start_timeout => :none,
                    :default_task_start_to_close_timeout => 60,
                    :default_task_schedule_to_close_timeout => :none,
                    :default_task_heartbeat_timeout => :none
                }
                options = default_options.merge options
                begin
                    activity_type = domain.activity_types.create name.to_s, version.to_s, options
                rescue AWS::SimpleWorkflow::Errors::TypeAlreadyExistsFault
                    # already registered
                    activity_type = domain.activity_types[name.to_s, version.to_s]
                end

                workers.times do
                    ProcessManager.register_worker self.to_s, loop_block_for_activity(activity_type)
                end
            end


            def loop_block_for_activity(activity_type)
                Proc.new do
                    if Glider::ProcessManager.use_forking
                        $0 = "ruby #{activity_type.name}-#{activity_type.version}"
                    end
                    register_signal_handlers
                    Glider.logger.info "Startig worker for #{activity_type.name} activity (pid #{Process.pid})"
                    loop do
                        begin
                            act_name = activity_type.name
                            Glider.logger.debug "Polling for task for #{act_name}"
                            before_polling_hook.call act_name if before_polling_hook
                            domain.activity_tasks.poll_for_single_task(act_name) do |activity_task|
                                task_lock! do
                                    begin
                                        wkf_id = activity_task.workflow_execution.workflow_id
                                        Glider.logger.info "Executing activity=#{act_name} workflow_id=#{wkf_id}"
                                        target_instance = self.new activity_task
                                        input = try_to_parse_as_json(activity_task.input)
                                        act_result = target_instance.send activity_type.name, input
                                         
                                        unless activity_task.responded?
                                            activity_task.complete! result: act_result.to_s
                                        end
                                    rescue AWS::SimpleWorkflow::ActivityTask::CancelRequestedError
                                        # cleanup after ourselves
                                        activity_task.cancel!
                                    end
                                end
                            end
                            after_polling_hook.call act_name if after_polling_hook
                        rescue AWS::SimpleWorkflow::Errors::UnknownResourceFault
                            $logger.error "Sent an action an expired task. Was the execution timeout span exceeded?"
                        rescue Glider::ProcessManager::ThreatExitSignal
                            execute_exit
                        rescue RuntimeError => e
                            if e.to_s == "already responded"
                                # this error sometimes appear if failing and completing happen very close
                                # in time and SWF doesn't report correctly the responded? status
                                Glider.logger.warn "Ignoring already responded error."
                            else
                                raise e
                            end
                        end
                    end
                end
            end


        end

    end

end