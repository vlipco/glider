
taken from docs.aws.amazon.com/amazonswf/latest/apireference/API_HistoryEvent.html


WorkflowExecutionStarted:
The workflow execution was started.

WorkflowExecutionCompleted:
The workflow execution was closed due to successful completion.

WorkflowExecutionFailed:
The workflow execution closed due to a failure.

WorkflowExecutionTimedOut:
The workflow execution was closed because a time out was exceeded.

WorkflowExecutionCanceled:
The workflow execution was successfully canceled and closed.

WorkflowExecutionTerminated:
The workflow execution was terminated.

WorkflowExecutionContinuedAsNew:
The workflow execution was closed and a new execution of the same type was created with the same workflowId.

WorkflowExecutionCancelRequested:
A request to cancel this workflow execution was made.

DecisionTaskScheduled:
A decision task was scheduled for the workflow execution.

DecisionTaskStarted:
The decision task was dispatched to a decider.

DecisionTaskCompleted:
The decider successfully completed a decision task by calling RespondDecisionTaskCompleted.

DecisionTaskTimedOut:
The decision task timed out.

ActivityTaskScheduled:
An activity task was scheduled for execution.

ScheduleActivityTaskFailed:
Failed to process ScheduleActivityTask decision. This happens when the decision is not configured properly, for example the activity type specified is not registered.

ActivityTaskStarted:
The scheduled activity task was dispatched to a worker.

ActivityTaskCompleted:
An activity worker successfully completed an activity task by calling RespondActivityTaskCompleted.

ActivityTaskFailed:
An activity worker failed an activity task by calling RespondActivityTaskFailed.

ActivityTaskTimedOut:
The activity task timed out.

ActivityTaskCanceled:
The activity task was successfully canceled.

ActivityTaskCancelRequested:
A RequestCancelActivityTask decision was received by the system.

RequestCancelActivityTaskFailed:
Failed to process RequestCancelActivityTask decision. This happens when the decision is not configured properly.

WorkflowExecutionSignaled:
An external signal was received for the workflow execution.

MarkerRecorded:
A marker was recorded in the workflow history as the result of a RecordMarker decision.

TimerStarted:
A timer was started for the workflow execution due to a StartTimer decision.

StartTimerFailed:
Failed to process StartTimer decision. This happens when the decision is not configured properly, for example a timer already exists with the specified timer Id.

TimerFired:
A timer, previously started for this workflow execution, fired.

TimerCanceled:
A timer, previously started for this workflow execution, was successfully canceled.

CancelTimerFailed:
Failed to process CancelTimer decision. This happens when the decision is not configured properly, for example no timer exists with the specified timer Id.

StartChildWorkflowExecutionInitiated:
A request was made to start a child workflow execution.

StartChildWorkflowExecutionFailed:
Failed to process StartChildWorkflowExecution decision. This happens when the decision is not configured properly, for example the workflow type specified is not registered.

ChildWorkflowExecutionStarted:
A child workflow execution was successfully started.

ChildWorkflowExecutionCompleted:
A child workflow execution, started by this workflow execution, completed successfully and was closed.

ChildWorkflowExecutionFailed:
A child workflow execution, started by this workflow execution, failed to complete successfully and was closed.

ChildWorkflowExecutionTimedOut:
A child workflow execution, started by this workflow execution, timed out and was closed.

ChildWorkflowExecutionCanceled:
A child workflow execution, started by this workflow execution, was canceled and closed.

ChildWorkflowExecutionTerminated:
A child workflow execution, started by this workflow execution, was terminated.

SignalExternalWorkflowExecutionInitiated:
A request to signal an external workflow was made.

ExternalWorkflowExecutionSignaled:
A signal, requested by this workflow execution, was successfully delivered to the target external workflow execution.

SignalExternalWorkflowExecutionFailed:
The request to signal an external workflow execution failed.

RequestCancelExternalWorkflowExecutionInitiated:
A request was made to request the cancellation of an external workflow execution.

ExternalWorkflowExecutionCancelRequested:
Request to cancel an external workflow execution was successfully delivered to the target execution.

RequestCancelExternalWorkflowExecutionFailed:
Request to cancel an external workflow execution failed.