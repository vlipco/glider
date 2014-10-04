
module Glider
    class Component
        class < self

            def swf
            end

            def enable_test_mode
                require "rspec/mocks/standalone"
                # create a fake domain collection
                fake_domains = instance_double "AWS::SimpleWorkflow::DomainCollection"
                # TODO initialize that collection to reply to some methods
                # allow the single SWF client to always reply with the fake domains object
                allow(Glider::Component.swf).to receive(:domains).and_return(fake_domains)
                single_domain = instance_double("AWS::SimpleWorkflow::Domain")
                allow(single_domain).to receive(:status).and_return(true) # irrelevant return value
                allow(fake_domains).to receive(:[]).and_return(single_domain)
                allow(Glider::Component).to receive(:completed_event_for).and_return(nil)
                allow(event).to receive(:event_type).and_return("MyFakeEvent")
                allow(Glider::Component).to receive(:decider_data_of).and_return( {key: 123}.to_json )
                let(:event){ instance_double "AWS::SimpleWorkflow::HistoryEvent" }
                task_double = instance_double "AWS::SimpleWorkflow::DecisionTask"
                execution_double = double(workflow_id: 'le_workflow')
                allow(task_double).to receive(:workflow_execution).and_return(execution_double)
                allow(task_double).to receive(:decisions).and_return([true])
            end
        end
    end
end