#!/bin/bash
# OssImport Console for Linux

#######################################################
# Define function
#######################################################

function usage()
{
    echo "Support command:"
    echo "    submit: submit job"
    echo "    start: start import service"
    echo "    stop: stop import service"
    echo "    clean: clean old job"
    echo "    stat: stat job"
    echo "    retry: retry all failed tasks"
    echo "    version: ossimport version"
}

function get_java_heap_max()
{
    if [ -e ${import_sys_conf} ]; then
        java_heap_line=$(grep "javaHeapMaxSize=" ${import_sys_conf} | tr -d '\r')
        if [ -n "$java_heap_line" ]; then
            java_heap=${java_heap_line#javaHeapMaxSize*=}
            if [ -z "$java_heap" ]; then
                java_heap="1024m"
            fi
            java_heap_max="-Xmx${java_heap}"
        fi
    else
        echo "Error: ossimport system configuration:${import_sys_conf} not found."
        exit 2
    fi
}

function start_import_service()
{
    get_java_heap_max
    nohup java ${java_heap_max} ${import_opts} -jar ${import_jar} -c ${import_sys_conf} start > ${work_dir}/logs/ossimport2.log 2>&1 &
    sleep 1s
    echo "Start import service completed."
}

function stop_import_service()
{
    ps axu | grep "ossimport2.jar.* start" | grep -v grep | awk '{print "kill -9 "$2}' | bash > /dev/null
    sleep 1s
    echo "Stop import service completed."
}

function submit_job()
{
    java -jar ${import_jar} -c ${import_sys_conf} submit ${work_dir}/conf/local_job.cfg > ${work_dir}/logs/submit.log 2>&1
    submit_result=$(grep "Error:" ${work_dir}/logs/submit.log)
    if [ -z "$submit_result" ]; then
        # successful
        cat ${work_dir}/logs/submit.log
    else
        # failed
        cat ${work_dir}/logs/submit.log
    fi
}

function clean_job()
{
    java -jar ${import_jar} -c ${import_sys_conf} clean ${job_name}
    echo "Clean job:${job_name} completed."
}

function stat_job()
{
    java -jar ${import_jar} -c ${import_sys_conf} stat detail
}

function retry_failed_tasks()
{
    java -jar ${import_jar} -c ${import_sys_conf} retry ${job_name} > ${work_dir}/logs/retry.log 2>&1
    retry_result=$(cat ${work_dir}/logs/retry.log)
    if [ -z "$retry_result" ]; then
        echo "None failed tasks for job:${job_name}."
    else
        cat ${work_dir}/logs/retry_result.log
        echo "Retry has been submitted."
    fi
    
}

function ver_import()
{
    java -jar ${import_jar} -c ${import_sys_conf} version
}

#######################################################
# Start of main
#######################################################

work_dir=
command=
job_name="local_test"
java_heap_max="-Xmx1024m"
import_opts=
import_jar=
import_sys_conf=

# check args
if [ "$#" -ne 1 ]; then
   usage
   exit 1
fi
command=$1

# get work dir
osname=$(uname)
if [ "$osname" = "Linux" ]; then
    work_dir=$( dirname $(readlink -f $0) )
else
    work_dir=$( cd "$( dirname "$0" )" && pwd )
fi

import_jar=${work_dir}/bin/ossimport2.jar
import_sys_conf=${work_dir}/conf/sys.properties

# cd to the root dir of ossimport
cd ${work_dir}

# execute command
case ${command} in
    start | Start)
        start_import_service
        ;;
    stop | Stop)
        stop_import_service
        ;;
    submit | Submit)
        submit_job
        ;;
    clean | Clean)
        clean_job
        ;;
    stat | Stat)
        stat_job
        ;;
    retry | Retry)
        retry_failed_tasks
        ;;
    version | Version)
        ver_import
        ;;
    *)
        usage
        exit 1
        ;;
esac
