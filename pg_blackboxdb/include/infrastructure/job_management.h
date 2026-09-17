/*-------------------------------------------------------------------------
 * Copyright (c) Anonymous.  All rights reserved.
 *
 * include/infrastructure/job_management.h
 *
 * Common declarations for the pg_blackboxdb job management.
 *
 *-------------------------------------------------------------------------
 */

#ifndef BLACKBOXDB_JOB_MANAGEMENT_H
#define BLACKBOXDB_JOB_MANAGEMENT_H

#define BLACKBOXDB_INDEX_BUILD_JOB1_JOBID 90
#define BLACKBOXDB_INDEX_BUILD_JOB2_JOBID 91

extern bool EnableBackgroundWorker;
extern bool EnableBackgroundWorkerJobs;
extern bool EnableBackgroundWorkerInitJobs;
extern bool EnableBgWorkerMetricsEmission;
extern bool IndexBuildsScheduledOnBgWorker;

/* index build tasks */
void UnscheduleIndexBuildTasks(char *extensionPrefix);
void ScheduleIndexBuildTasks(char *extensionPrefix);
void RegisterIndexBuildBackgroundWorkerJobs(void);

#endif
