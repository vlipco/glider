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
	    
	    let(:event){ instance_double "AWS::SimpleWorkflow::HistoryEvent" }

	    let(:task) do
	        task_double = instance_double "AWS::SimpleWorkflow::DecisionTask"
	        execution_double = double(workflow_id: 'le_workflow')
	        allow(task_double).to receive(:workflow_execution).and_return(execution_double)
	        allow(task_double).to receive(:decisions).and_return([true])
	        next task_double
	    end

	    it "skips all muted events" do
	        allow(Glider::Component).to receive(:completed_event_for).and_return(nil)
	        allow(Glider::Component).to receive(:decider_data_of).and_return({})
	        allow_any_instance_of(Glider::Component).to receive(:test_decider).and_return(true)

	        to_skip = %w(
    	        ActivityTaskScheduled
                ActivityTaskStarted
                DecisionTaskScheduled
                DecisionTaskStarted
                DecisionTaskCompleted
                MarkerRecorded
                TimerStarted
                StartChildWorkflowExecutionInitiated
                StartChildWorkflowExecutionStarted
                SignalExternalWorkflowExecutionInitiated
                RequestCancelExternalWorkflowExecutionInitiated )
            to_skip.each do |sk|
	            allow(event).to receive(:event_type).and_return(sk)
	            did_process = Glider::Component.send :process_workflow_event, event, task, :test_decider
	            expect(did_process).to be(false)
	        end
	    end
	end
	
	describe "activity"do
	end
end