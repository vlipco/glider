require 'spec_helper'

describe Glider::Component do
    
    let(:fake_domains) { instance_double "AWS::SimpleWorkflow::DomainCollection" }
    
    before :each do
        allow(Glider::Component.swf).to receive(:domains).and_return(fake_domains)
    end
    
    it "creates a domain if it's missing" do
        allow(fake_domains).to receive(:[]).and_raise(AWS::SimpleWorkflow::Errors::UnknownResourceFault)
        #swf.domains.create(domain_name.to_s, retention_period)
        expect(fake_domains).to receive(:create).with("le_domain", 10)
        Glider::Component.domain :le_domain
    end
    
    it "uses a domain if already present" do
        single_domain = instance_double("AWS::SimpleWorkflow::Domain")
        allow(single_domain).to receive(:status).and_return(true) # irrelevant return value
        allow(fake_domains).to receive(:[]).and_return(single_domain)
        expect(fake_domains).not_to receive(:create)
    end

    describe "workflow"do

        before(:each) do
            allow(Glider::Component).to receive(:completed_event_for).and_return(nil)
            allow_any_instance_of(Glider::Component).to receive(:test_decider).and_return(true)
            allow(event).to receive(:event_type).and_return("MyFakeEvent")
            allow(Glider::Component).to receive(:decider_data_of).and_return( {key: 123}.to_json )
        end

        let(:event){ instance_double "AWS::SimpleWorkflow::HistoryEvent" }

        let(:task) do
            task_double = instance_double "AWS::SimpleWorkflow::DecisionTask"
            execution_double = double(workflow_id: 'le_workflow')
            allow(task_double).to receive(:workflow_execution).and_return(execution_double)
            allow(task_double).to receive(:decisions).and_return([true])
            next task_double
        end

        
        
        it "executes the correct handling method with the correct context" do
            allow(Glider::Component).to receive(:decider_data_of).and_return("le_data")

            fake_implementation = double "fake_implementation"
            allow(Glider::Component).to receive(:new).and_return(fake_implementation)

            expect(fake_implementation).to receive(:test_decider).with(:my_fake_event, event, 'le_data')
            did_process = Glider::Component.send :process_workflow_event, event, task, :test_decider
            expect(did_process).to be(true)
        end

    end
    
    describe "activity" do
        
        it "captures untrapped exceptions"
        it "converts JSON input to a ruby hash"
        it "send the method resolt to SWF"
    end
end