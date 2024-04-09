#!/bin/bash
# One Key Import for Linux

#######################################################
# Define function
#######################################################

function yes_or_no()
{
    while [ true ]               
    do
       echo -n "$*, Yes or No: "
       read x
       case "$x" in
         y | Y | yes | Yes | YES ) return 0;;
         n | N | no | No | NO ) return 1;;
         * ) echo "Answer yes or no"
       esac
    done
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
    ps axu | grep "ossimport2.jar.* start" | grep -v grep | awk '{print "kill -9 "$2}' | bash > /dev/null 2>&1
    sleep 1s
    echo "Stop import service completed."
}

function submit_job()
{
    java -jar ${import_jar} -c ${import_sys_conf} submit $work_dir/conf/local_job.cfg > ${work_dir}/logs/submit.log 2>&1
    submit_result=$(grep "Error:" ${work_dir}/logs/submit.log)
}

function clean_job()
{
    java -jar ${import_jar} -c ${import_sys_conf} clean ${job_name}
    echo "Clean job:${job_name} completed."
}

function stat_job()
{
    java -jar ${import_jar} -c ${import_sys_conf} stat detail > ${work_dir}/logs/job_stat.log 2>&1
    cat ${work_dir}/logs/job_stat.log
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

#######################################################
# Start of main
#######################################################

work_dir=
job_name="local_test"
submit_result=
java_heap_max="-Xmx1024m"
import_opts=
import_jar=
import_sys_conf=

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

# submit job
while [ 0 ]; do
    submit_job
    if [ -z "$submit_result" ]; then
        # successful
        cat ${work_dir}/logs/submit.log
        break
    else
        # failed
        yes_or_no "Clean the previous job"
        is_clean_job=$?
        if [ $is_clean_job == 0 ]; then
            stop_import_service
            clean_job
        else
            exit 1
        fi
    fi
done


# start service
start_import_service

# stat
while [ 0 ]; do
    sleep 5s
    stat_job 

    # job failed
    is_job_failed=$(grep "JobState:Failed" ${work_dir}/logs/job_stat.log)
    if [ -n "$is_job_failed" ]; then
        yes_or_no "Retry the failed tasks"
        is_retry=$?
        if [ $is_retry == 0 ]; then
            retry_failed_tasks
        else
            exit 2
        fi
    fi
    
    # job successful
    is_job_completed=$(grep "JobState:Succeed" ${work_dir}/logs/job_stat.log)
    if [ -n "$is_job_completed" ]; then
        break
    fi
done
echo "Import to oss completed."

# stop service
yes_or_no "Stop import service"
is_stop_service=$?
if [ $is_stop_service == 0 ]; then
    stop_import_service
fi

exit 0
