@rem OssImport console for Windows

@echo off
set curdir=%~dp0
cd /d %curdir%
setlocal enabledelayedexpansion

set CMD_JAR=bin/ossimport2.jar
set SYS_CONF=conf/sys.properties
set JOB_CONF=conf/local_job.cfg
set JOB_NAME=local_test

rem sumbmit job
if /i "%1" == "submit" (
    java -jar %CMD_JAR% -c %SYS_CONF% submit %JOB_CONF% 2>&1
    goto COMPETE
)

rem start migration or/and verification
if /i "%1" == "start" (
    start java -jar -Xmx1024m %CMD_JAR% -c %SYS_CONF% start 2>&1
    goto COMPETE
)

rem clean remaining job
if /i "%1" == "clean" (
    java -jar %CMD_JAR% -c %SYS_CONF% clean %JOB_NAME%
    goto COMPETE
)

rem view job status
if /i "%1" == "stat" (
    java -jar %CMD_JAR% -c %SYS_CONF% stat detail
    goto COMPETE
)

rem retry failed tasks
if /i "%1" == "retry" (
    java -jar %CMD_JAR% -c %SYS_CONF% retry %JOB_NAME%
    goto COMPETE
)

rem print version
if /i "%1" == "version" (
    java -jar %CMD_JAR% -c %SYS_CONF% version
    goto COMPETE
)

rem invalid command
echo Support command:
echo    submit: submit job
echo    start: start import service
echo    clean: clean old job
echo    stat: stat job
echo    retry: retry all failed tasks
echo    version: ossimport version
goto QUIT

rem job competed and exit
:COMPETE
echo %1 competed

rem error occurred and exit
:QUIT
