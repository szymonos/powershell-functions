/* Jobs definitions */
select
    j.job_name
   ,j.job_version
   ,j.description
   ,j.enabled
   ,j.schedule_interval_type
   ,j.schedule_interval_count
   ,schedule_start_time = convert(char(19), cast(j.schedule_start_time as datetimeoffset)at time zone 'Central European Standard Time', 120)
   ,schedule_end_time = convert(char(19), cast(j.schedule_end_time as datetimeoffset)at time zone 'Central European Standard Time', 120)
from
    jobs.jobs as j
order by
    j.job_name;

/* Job steps definitions */
select
    j.job_name
   ,js.step_id
   ,js.step_name
   ,js.command_type
   ,js.command_source
   ,js.command
   ,js.credential_name
   ,js.target_group_name
from
    jobs.jobs as j
    inner join jobs.jobsteps as js
        on js.job_id = j.job_id and js.job_version = j.job_version
order by
    j.job_name
   ,js.step_id;
