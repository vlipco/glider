require 'spec_helper'

describe Glider::Component do
    
    let(:fake_domains) { instance_double "AWS::SimpleWorkflow::DomainCollection" }
    
    before :each do
        allow(Glider.swf).to receive(:domains).and_return(fake_domains)
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

    let(:execution) do
        execution_double = instance_double "AWS::SimpleWorkflow::WorkflowExecution", { workflow_id: 'le_workflow' }
        allow(execution_double).to receive_message_chain( :workflow_type, name: 'test_decider')
        next execution_double
    end

    describe "workflow"do

        let(:event) do
            instance_double "AWS::SimpleWorkflow::HistoryEvent", {
                decision_data: 'le_data', signature: 'xxx', name: 'my_fake_event'
            }
        end

        let(:task) do
            instance_double "AWS::SimpleWorkflow::DecisionTask", {
                class: AWS::SimpleWorkflow::DecisionTask,
                workflow_execution: execution,
                decisions: [true]
            }
        end

        it "terminates itself when there's an untrapped exception" do
            allow_any_instance_of(Glider::Component).to receive(:test_decider).and_raise(NoMethodError)
            expect(task).to receive('fail_workflow_execution')
            target_instance = Glider::Component.new(task,event)
            target_instance.process
        end
        
    end
    
    describe "activity" do

        let(:task) do
            activity_double = instance_double "AWS::SimpleWorkflow::ActivityTask", {
                'class' => AWS::SimpleWorkflow::ActivityTask,
                'input' => 'le_input',
                'responded?' => false,
                'workflow_execution' => execution,
                'signature' => 'xxx'
            }
            allow(activity_double).to receive_message_chain('activity_type.name').and_return('test_activity')
            next activity_double
        end
        let(:target_instance) { Glider::Component.new task }

        it "captures untrapped exceptions" do
            allow(target_instance).to receive(:test_activity).and_raise(NoMethodError)
            expect(task).to receive('fail!')
            target_instance.process
        end

        it "sends the method result to SWF" do
            allow(target_instance).to receive(:test_activity).and_return('le_result')
            expected_args = { result: "le_result" }
            expect(task).to receive('complete!').with(expected_args)
            target_instance.process
            
        end
    end
end