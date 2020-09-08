with jm
as (
   select
       j.name
      ,je.step_id
      ,js.step_name
      ,Command = cd.text
      ,je.is_active
      ,je.lifecycle
      ,duration = dbo.TS2Time(datediff(ms, je.start_time, isnull(je.end_time, getdate())))
      ,start_time = convert(char(19), cast(je.start_time as datetimeoffset)at time zone 'Central European Standard Time', 120)
      ,end_time = convert(char(19), cast(je.end_time as datetimeoffset)at time zone 'Central European Standard Time', 120)
      ,current_attempts = je.current_task_attempts
      ,last_message = case
                          -- Error messages
                          when jte.is_active = 0 and jte.message is not null then jte.message
                          when prev_jte.message is not null then prev_jte.message
                          -- Any tasks in Created state that haven't been dequeued by a worker yet --
                          when jte.lifecycle = 'Created' then 'Waiting for available worker...'
                          -- Target level execution
                          when je.lifecycle = 'Created' then
                               formatmessage(
                                   'Step %i preparing execution for target (server ''%s'', database ''%s'').', js.step_id, t.server_name, t.database_name)
                          when je.lifecycle = 'InProgress' then
                               formatmessage('Step %i executing on target (server ''%s'', database ''%s'').', js.step_id, t.server_name, t.database_name)
                          when je.lifecycle = 'WaitingForRetry' then
                               formatmessage(
                                   'Step %i waiting for retry on target (server ''%s'', database ''%s'').', js.step_id, t.server_name, t.database_name)
                          when je.lifecycle = 'Succeeded' then
                               formatmessage(
                                   'Step %i succeeded execution on target (server ''%s'', database ''%s'').', js.step_id, t.server_name, t.database_name)
                          when je.lifecycle = 'Canceled' then
                               formatmessage(
                                   'Step %i canceled execution on target (server ''%s'', database ''%s'').', js.step_id, t.server_name, t.database_name)
                          when je.lifecycle = 'Skipped' then
                               formatmessage(
                                   'Step %i skipped execution because a previous execution of this job is still running on this target (server ''%s'', database ''%s'').'
                                  ,js.step_id, t.server_name, t.database_name)
                          when je.lifecycle = 'TimedOut' then
                               formatmessage('Step %i timed out on target (server ''%s'', database ''%s'').', js.step_id, t.server_name, t.database_name)
                          -- Step level execution
                          when je.lifecycle = 'Created' then formatmessage('Step %i preparing targets.', js.step_id)
                          when je.lifecycle = 'InProgress' then formatmessage('Step %i evaluating targets.', js.step_id)
                          when je.lifecycle = 'WaitingForChildJobExecutions' then
                               formatmessage('Step %i waiting for execution on targets to complete.', js.step_id)
                          when je.lifecycle = 'WaitingForRetry' then formatmessage('Step %i waiting for retry.', js.step_id)
                          when je.lifecycle = 'Succeeded' then formatmessage('Step %i succeeded.', js.step_id)
                          when je.lifecycle = 'SucceededWithSkipped' then
                               formatmessage('Step %i succeeded with skipped executions on some targets.', js.step_id)
                          when je.lifecycle = 'Canceled' then formatmessage('Step %i canceled.', js.step_id)
                          when je.lifecycle = 'Skipped' then formatmessage('Step %i skipped executions on targets.', js.step_id)
                          when je.lifecycle = 'Failed' then formatmessage('Step %i failed.', js.step_id)
                          when je.lifecycle = 'TimedOut' then formatmessage('Step %i timed out.', js.step_id)end
      ,rn = row_number() over (partition by
                                   je.job_id
                                  ,je.step_id
                               order by
                                   je.start_time desc
                                  ,je.current_task_attempts desc)
   from
       jobs_internal.jobs as j
       inner join jobs_internal.job_executions as je
           on je.job_id = j.job_id and je.step_id is not null
       inner join jobs_internal.jobsteps as js
           on js.job_id = je.job_id and js.step_id = je.step_id and js.job_version_number = je.job_version_number
       inner join jobs_internal.jobstep_data as sd
           on sd.jobstep_data_id = js.jobstep_data_id
       inner join jobs_internal.targets as t
           on je.target_id = t.target_id and t.target_type <> 'TargetGroup'
       left outer join jobs_internal.command_data as cd
           on sd.command_data_id = cd.command_data_id
       left outer join jobs_internal.job_task_executions as jte
           on je.last_job_task_execution_id = jte.job_task_execution_id
       left outer join jobs_internal.job_task_executions as prev_jte
           on jte.previous_job_task_execution_id = prev_jte.job_task_execution_id
   where
       j.delete_requested_time is null
       and j.is_system = 0
   )
select
    *
from
    jm
where
    rn = 1 --
order by
    start_time desc
