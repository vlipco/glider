require_relative 'boot'

ITERATION = 2.4

class Deciders < Glider::Component

    domain :gt3

    register_workflow :say_hi, ITERATION
    register_activity :signaler, ITERATION

    before_polling do |workflow_name|
        Glider::logger.info ">"
    end

    after_polling do |workflow_name|
        Glider::logger.info "<"
    end

    def say_hi(event_name, data)
        case event_name
        when :workflow_execution_started
            Glider.logger.info "--> say_hi workflow started with data.keys=#{data.keys} data.class=#{data.class}"
            Glider.logger.info "--> message='#{data[:message]}'"
            Glider.logger.info "--> Scheduling hello_world activity and passing the input"
            #binding.pry
            task.schedule_activity_task activity(:hello_world, ITERATION), input: 'NO_FAIL'
            task.complete!
        when :hello_world_activity_timed_out
            if event.control == 'RETRY'
                Glider.logger.error 'failed on second retry'
            else
                Glider.logger.warn "retrying hello world"
                task.schedule_activity_task activity(:hello_world, ITERATION), control: 'RETRY'
            end
        when :close_signal
            Glider.logger.info "--> Received close signal !!!!!!! <--".green
            task.complete_workflow_execution result: 'close_signal_received'
        when :hello_world_activity_completed
            if data == 'hello!'
                Glider.logger.info "--> hello_world completed with the expected result of 'hello!'"
            else
                Glider.logger.info "--> hello_world completed but the result wasn't 'hello!'"
            end
            Glider.logger.info "--> Scheduling slow_worker with a timeout of 1 seconds to make it fail"
            task.schedule_activity_task activity(:slow_worker, ITERATION), start_to_close_timeout: 1
            #binding.pry
        when :slow_worker_activity_timed_out, :failing_worker_activity_timed_out
            Glider.logger.info "--> slow_worker timeout reported as expected"
            Glider.logger.info "--> Scheduling failing_worker to ensure the exception is caught and reported"
            task.schedule_activity_task activity(:failing_worker, ITERATION)
        when :failing_worker_activity_failed
            Glider.logger.info "--> failing_worker exception was reported correctly data=#{data}"
            Glider.logger.info "--> Scheduling signaler with workflow execution id to indicate it's close time"
            task.signal_external_workflow_execution workflow_execution.id, 'close',
                control: 'le_control', input: 'le_input'
        end
    end

    def signaler(workflow_id)
        Glider.logger.info "--> Executing signaler activity to send close signal to workflow_id=#{workflow_id}"
        Glider.signal :gt3, workflow_id, :close
    end

end

class Workers < Glider::Component

    domain :gt3

    register_activity :hello_world, ITERATION
    register_activity :slow_worker, ITERATION
    register_activity :failing_worker, ITERATION
    
    #before_polling do |workflow_name|
    #    Glider::logger.info "before_polling: #{workflow_name}"
    #end
    #after_polling do |workflow_name|
    #    Glider::logger.info "after_polling: #{workflow_name}"
    #end
    

    def hello_world(input)
        Glider.logger.info "### Executing hello_world activity with input=#{input}"
        sleep 10 if input == 'DO_FAIL'
        Glider.logger.info "### Completing hello_world with result='Hello!'}"
        return "hello!"
    end
    
    def slow_worker(input)
        Glider.logger.info "### Executing slow_worker activity for 3 seconds to cause timeout"
        sleep 3
        return "this result should never endup in the activity being completed"
    end
    
    def failing_worker(input)
        Glider.logger.info "### Raising exception from failing worker"
        raise "I'm a worker that fails, don't mind this error"
    end

end

input = {message: "please salute! #{Time.now.to_i}"}.to_json
Glider.logger.info "--> Triggering workflow execution with input=#{input}"
execution = Glider.execute :gt3, :say_hi, ITERATION,
    input: input,
    task_start_to_close_timeout: 3,
    execution_start_to_close_timeout: 200
Glider.logger.info "--> Execution triggered id=#{execution.id}"
#binding.pry
# TODO create a failing decider and confirm that the exception is caught and the
# execution is aborted
#Spawnling.wait Deciders.start_pollers

Glider::Component.start_all_pollers_and_block

#binding.pry