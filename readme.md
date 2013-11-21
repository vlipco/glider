Useful documentation links:

http://docs.aws.amazon.com/amazonswf/latest/apireference/API_RespondDecisionTaskCompleted.html

http://docs.aws.amazon.com/amazonswf/latest/apireference/API_HistoryEvent.html

http://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-workflow-exec-lifecycle.html

USEFUL TO DECIDE WHAT TO PASS TO THE METHOD

INFO 15:16:05 	Starting workers for ["hello_world-1.0"] and ["say_hi-1.0"]
INFO 15:16:05 	Startig worker for say_hi (class: MySWF)
INFO 15:16:42 	Processing decision task workflow_id=bb235559-9ee6-4a80-96c5-9eed168046d5
INFO 15:16:42 	say_hi event=workflow_execution_started data=ALOHA
WARN 15:16:42 	No result for decision_task_scheduled, attributes: {:task_list=>"say_hi", :start_to_close_timeout=>5}
WARN 15:16:42 	say_hi event=decision_task_scheduled data=
WARN 15:16:42 	No result for decision_task_started, attributes: {:identity=>"dmb.local:49424", :scheduled_event_id=>2}
WARN 15:16:42 	say_hi event=decision_task_started data=
WARN 15:16:42 	No result for decision_task_timed_out, attributes: {:timeout_type=>"START_TO_CLOSE", :scheduled_event_id=>2, :started_event_id=>3}
WARN 15:16:42 	say_hi event=decision_task_timed_out data=
WARN 15:16:42 	No result for decision_task_scheduled, attributes: {:task_list=>"say_hi", :start_to_close_timeout=>5}
WARN 15:16:42 	say_hi event=decision_task_scheduled data=
WARN 15:16:42 	No result for decision_task_started, attributes: {:identity=>"dmb.local:49461", :scheduled_event_id=>5}
WARN 15:16:42 	say_hi event=decision_task_started data=
DEBUG 15:16:42 	[{:decision_type=>"CompleteWorkflowExecution", :complete_workflow_execution_decision_attributes=>{}}]

terminations dont trigger decisions