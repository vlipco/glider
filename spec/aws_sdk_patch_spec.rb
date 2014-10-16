require 'spec_helper'

describe AWS::SimpleWorkflow::WorkflowExecution do
    
    let :fake_execution do
        fake_execution = AWS::SimpleWorkflow::WorkflowExecution.new nil, 123, 456
        allow(fake_execution).to receive('history_events').and_return([fake_event])
        next fake_execution
    end
    
    let(:fake_event){ instance_double AWS::SimpleWorkflow::HistoryEvent }

    it "detects when the workflow has previous decisions" do
        allow(fake_event).to receive('raw_name').and_return(:decision_task_completed)
        expect(fake_execution.has_previous_decisions?).to be(true)
    end
    
    it "detects when the workflow doesn't have previous decisions" do
        allow(fake_event).to receive('raw_name').and_return(:whatever)
        expect(fake_execution.has_previous_decisions?).to be(false)
    end

end

describe AWS::SimpleWorkflow::HistoryEvent do
    
    let(:fake_execution) { instance_double AWS::SimpleWorkflow::WorkflowExecution }
    
    let :fake_event do
        event_details = { 'eventType' => 'xyz', 'eventId' => '123', 'eventTimestamp' => Time.now.to_i }
        event = AWS::SimpleWorkflow::HistoryEvent.new fake_execution, event_details
        allow(event).to receive('attributes').and_return(double('fake_attributes'))
        allow(event).to receive('activity_name').and_return('le_action')
        next event
    end
    
    it "handles muted events correctly" do
        
        %w(
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
            RequestCancelExternalWorkflowExecutionInitiated
        ).each do |sk|
            event_details = { 'eventType' => sk, 'eventId' => '123', 'eventTimestamp' => Time.now.to_i }
            event = AWS::SimpleWorkflow::HistoryEvent.new fake_execution, event_details
            expect(event.muted?).to be(true)
        end
    end

    context 'name' do

        it 'changes when the event is a signal' do
            allow(fake_event).to receive('raw_name').and_return(:workflow_execution_signaled)
            allow(fake_event.attributes).to receive('signal_name').and_return('termination')
            expect(fake_event.name).to equal(:termination_signal)
        end

        it 'changes when a task has completed' do
            allow(fake_event).to receive('raw_name').and_return(:activity_task_completed)
            expect(fake_event.name).to equal(:le_action_activity_completed)
        end
        
        it 'changes when a task has failed' do
            allow(fake_event).to receive('raw_name').and_return(:activity_task_failed)
            expect(fake_event.name).to equal(:le_action_activity_failed)
        end
        it 'changes when a task has timed out' do
            allow(fake_event).to receive('raw_name').and_return(:activity_task_timed_out)
            expect(fake_event.name).to equal(:le_action_activity_timed_out)
        end
    

        it 'does not change unless is a special case' do
            allow(fake_event).to receive('raw_name').and_return(:whatever)
            expect(fake_event.name).to equal(:whatever)
        end
    end
    
    context 'decision data' do
        before do
            allow(fake_event.attributes).to receive('input').and_return('le_input')
            allow(fake_event.attributes).to receive('reason').and_return('le_reason')
            allow(fake_event.attributes).to receive('result').and_return('le_result')
        end
        it 'is the workflow input when it begins' do
            allow(fake_event).to receive('raw_name').and_return(:workflow_execution_started)
            expect(fake_event.decision_data).to eq('le_input')
            
        end
        it 'is the signal input when it is sent' do
            allow(fake_event).to receive('raw_name').and_return(:workflow_execution_signaled)
            expect(fake_event.decision_data).to eq('le_input')
        end

        it 'is the failure reason when an activity failed' do
            allow(fake_event).to receive('raw_name').and_return(:activity_task_failed)
            expect(fake_event.decision_data).to eq('le_reason')
        end
        it 'is parsed as JSON' do
            # indifferent access used for hash equality comparison
            result = ActiveSupport::HashWithIndifferentAccess.new( { key: "something" } )
            allow(fake_event.attributes).to receive('result').and_return(result.to_json)
            expect(fake_event.decision_data).to eq(result)
        end
        it 'is the result attribute in non special cases' do
            allow(fake_event).to receive('raw_name').and_return(:activity_task_timed_out)
            expect(fake_event.decision_data).to eq('le_result')
        end
    end

end # HistoryEvent cases end

