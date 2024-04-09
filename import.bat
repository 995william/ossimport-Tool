@rem Script for quick migration on Windows

@echo off
set curdir=%~dp0
cd /d %curdir%
setlocal enabledelayedexpansion

echo Submitting the migration job...

:submit
java -jar bin/ossimport2.jar -c conf/sys.properties  submit conf/local_job.cfg 2>&1 | find "please clean it first" > nul && (
:isNeedClear
    set/p in="A migration job with the same name existed. Enter [y] to delete the job and restart, or enter [n] to resume from the last breakpoint. (y/n)?"
    if /i "!in!"=="y"  (
        echo Cleaning the existing job...
        java -jar bin/ossimport2.jar -c conf/sys.properties clean local_test
        echo The job is cleaned!
        goto submit
    )
    if /i "!in!"=="n"  (
        goto start
    ) 
    echo Input error "!in!"
    goto isNeedClear
) 

echo The migration job submitted successfully!

:start
echo Starting the migration job...
start java -jar -Xmx1024m bin/ossimport2.jar -c conf/sys.properties start 2>&1

:stat
java -jar bin/ossimport2.jar -c conf/sys.properties stat detail >logs/job_stat.log
type logs\job_stat.log
find "JobState:Failed" logs\job_stat.log > nul && (
:isNeedRetry
    set/p in="The migration job completed and some tasks failed. Try the failed tasks again. (y/n)?"
    if /i "!in!"=="y"  (
        java -jar bin/ossimport2.jar -c conf/sys.properties retry local_test
        goto stat
    )
    if /i "!in!"=="n"  (
        goto end
    )
    echo Input error "!in!"
    goto isNeedRetry
)
find "JobState:Succeed" logs\job_stat.log > nul && (
    echo The migration job completed successfully!
    goto end
)
@ping -n 10 127.1>nul
goto stat

:end
echo Migration completed. Close the prompted window and press any key to exit.
pause
