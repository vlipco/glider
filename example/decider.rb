require_relative 'boot'

class MySWF < Glider::Component

    #workers 1
    domain :gt3

    register_workflow :say_hi, '1.5'
    register_workflow :say_bye, '1.0'

    before_polling do |workflow_name|
        Glider::logger.info "BEFORE POLLING #{workflow_name} pid=#{Process.pid}"
    end

    after_polling do |workflow_name|
        Glider::logger.info "AFTER POLLING OK #{workflow_name} pid=#{Process.pid}"
    end

    def say_hi(event_name, data)
        case event_name
        when :workflow_execution_started, :hello_world_activity_timed_out
            task.schedule_activity_task activity(:hello_world, 1.5), input: data.to_json
        when :test_signal
            # do what?
        when :hello_world_activity_failed
            $logger.error "EXPECTED ERROR!"
        when :hello_world_activity_completed
            task.complete_workflow_execution result: data
        end
    end
    
    def say_bye(event_name, data)
        Glider.logger "Saying goodbye!"
        task.complete_workflow_execution result: "goodbye"
    end

end

MySWF.start_pollers

#poller = MySWF.send(:pollers)[0]

#Glider::ProcessManager.start_workers from_class: MySWF

#binding.pry