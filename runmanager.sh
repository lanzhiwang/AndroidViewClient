#!/usr/bin/env bash
#
# Perform and manage startmanager python.

# */5  *  *  *  * root cd /opt/pscms_appmonitor_staticanalysis/scanos_backend/com/rzx && bash runmanager.sh

startmanager_count=$(ps -ef | grep '/opt/pscms_appmonitor_staticanalysis/scanos_backend/com/rzx/startmanager.py' | grep -v grep | awk '{print $9}' | wc -l)
echo ${startmanager_count}

runmanager_file_size=$(du -sm runmanager.log | awk '{print $1}')
echo ${runmanager_file_size}

if [[ ${runmanager_file_size} -gt 20 ]]; then
  ps -ef | grep '/opt/pscms_appmonitor_staticanalysis/scanos_backend/com/rzx/startmanager.py' | grep -v grep | awk '{print $2}' | xargs kill -9
  rm -rf runmanager.log
  nohup python runmanager.py > runmanager.log 2>&1 &

else
  if [[ ${startmanager_count} -eq 0 ]]; then
    rm -rf runmanager.log
    nohup python runmanager.py > runmanager.log 2>&1 &
  elif [[ ${startmanager_count} -eq 1 ]]; then
    :
  else
    pid_arr=($(ps -ef | grep '/opt/pscms_appmonitor_staticanalysis/scanos_backend/com/rzx/startmanager.py' | grep -v grep | awk '{print $2}'))
    echo ${pid_arr[@]}
    echo ${#pid_arr[@]}
    i=1
    while [[ "$i" -lt "${#pid_arr[@]}" ]]; do
      kill -9 ${pid_arr[${i}]}
      let "i=i+1"
    done

  fi

fi
