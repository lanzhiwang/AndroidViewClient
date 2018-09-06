#!/usr/bin/env bash

#set -x

# 手机设置
# 开发者选项连接USB
# [设置]->[显示]->[休眠]，最长时间休眠
# 开发者选项，保持唤醒状态
# 开始屏幕最好只有一页，不强求
# ROOT
# 检查网络设置
# 及时清理手机内存，卸载APK带有残留

#1、下载
#2、解包获取包名
#3、检查是否安装，没有安装就安装
#4、检查安装是否成功
#5、检查是否运行，停止运行，重新运行
#6、获取屏幕控件信息

dos2unix apk_url.txt

task=0
for line in $(cat apk_url.txt); do
  begin_time=$(date "+%s")
  let "task=task+1"
  echo "**********************************************************************************"
  echo "****************************************任务"${task}"*************************************"
  echo "**********************************************************************************"

  echo "======初始化相关目录======"
  if [ -e ./apk_temp ]; then
    rm -rf ./apk_temp
    mkdir ./apk_temp
  else
    mkdir ./apk_temp
  fi

  echo "======下载APK======"
  echo ${line}
  wget ${line} -O ./apk_temp/temp.apk > /dev/null 2>&1

  echo "======解析APK相关信息======"
  aapt dump badging ./apk_temp/temp.apk > ./apk_temp/apk_info.log
  if [ $? -gt 0 ]; then
    echo "?????解析APK相关信息不成功?????"
    end_time=`date "+%s"`
    run_time=$((end_time-begin_time))
    echo "总运行时间: "${run_time}
    continue
  fi
  cat ./apk_temp/apk_info.log | grep "package: name"
  cat ./apk_temp/apk_info.log | grep "launchable-activity: name"
  package_name=`cat ./apk_temp/apk_info.log | grep "package: name" | awk '{print $2}' | cut -d "'" -f 2`
  echo ${package_name}
  launchable_activity=`cat ./apk_temp/apk_info.log | grep "launchable-activity: name" | awk '{print $2}' | cut -d "'" -f 2`
  echo ${launchable_activity}

  echo "======尝试安装APK======"
  is_install=`adb -s 48db50a5b827 shell pm list packages -f | grep ${package_name}`

  if [ ${#is_install} == 0 ]; then
    adb -s 48db50a5b827 install ./apk_temp/temp.apk > /dev/null 2>&1
  fi

  is_install=`adb -s 48db50a5b827 shell pm list packages -f | grep ${package_name}`
  if [ ${#is_install} != 0 ]; then
    echo "======APK安装成功======"
  else
    echo "?????APK安装失败?????"
    adb -s 48db50a5b827 uninstall ${package_name}
    end_time=`date "+%s"`
    run_time=$((end_time-begin_time))
    echo "总运行时间: "${run_time}
    continue
  fi

  echo "======开始运行APK======"
  adb -s 48db50a5b827 shell am force-stop ${package_name}
  sleep 2
  adb -s 48db50a5b827 shell am start -n ${package_name}/${launchable_activity}
  sleep 10  # 等待时间设置太长有可能自动跳过相关设置界面，设置太短有可能屏幕解析出差，综合考虑设置时间长一点，以便让屏幕解析正确
  # 判断是否运行成功
  process_count=$(adb -s 48db50a5b827 shell ps | grep ${package_name} | wc -l)
  if [ ${process_count} -gt 0 ]; then
    echo "======APK运行成功======"
  else
    echo "?????APK运行失败?????"
    adb -s 48db50a5b827 uninstall ${package_name}
    end_time=`date "+%s"`
    run_time=$((end_time-begin_time))
    echo "总运行时间: "${run_time}
    continue
  fi

  echo "======第一次进入APK后的界面======"
  dump -c 48db50a5b827
  echo $?

  # 判断是否回到了桌面
  # 允许 确认 已阅读并同意 同意并授权 跳过 接受 同意 继续 确定 开始使用 同意并继续 开始体验 立即体验 马上体验
  # 允许|确认|已阅读并同意|同意并授权|跳过|接受|同意|继续|确定|开始使用|同意并继续|开始体验|立即体验|马上体验
  echo "======设置相关权限页面======"
  i=0
  while [[ ${i} -lt 10 ]]; do
    dump -c 48db50a5b827 > ./apk_temp/index_screen.log
    sleep 2
    dos2unix ./apk_temp/index_screen.log
    cat ./apk_temp/index_screen.log
    x_coordinate=$(cat ./apk_temp/index_screen.log | egrep '[[:space:]]允许[[:space:]]|[[:space:]]确认[[:space:]]|[[:space:]]已阅读并同意[[:space:]]|[[:space:]]同意并授权[[:space:]]|[[:space:]]跳过[[:space:]]|[[:space:]]接受[[:space:]]|[[:space:]]同意[[:space:]]|[[:space:]]继续[[:space:]]|[[:space:]]确定[[:space:]]|[[:space:]]开始使用[[:space:]]|[[:space:]]同意并继续[[:space:]]|[[:space:]]开始体验[[:space:]]|[[:space:]]立即体验[[:space:]]|[[:space:]]马上体验[[:space:]]' | cut -d '(' -f 2 | cut -d ')' -f 1 | awk -F ',' '{print $1}')
    y_coordinate=$(cat ./apk_temp/index_screen.log | egrep '[[:space:]]允许[[:space:]]|[[:space:]]确认[[:space:]]|[[:space:]]已阅读并同意[[:space:]]|[[:space:]]同意并授权[[:space:]]|[[:space:]]跳过[[:space:]]|[[:space:]]接受[[:space:]]|[[:space:]]同意[[:space:]]|[[:space:]]继续[[:space:]]|[[:space:]]确定[[:space:]]|[[:space:]]开始使用[[:space:]]|[[:space:]]同意并继续[[:space:]]|[[:space:]]开始体验[[:space:]]|[[:space:]]立即体验[[:space:]]|[[:space:]]马上体验[[:space:]]' | cut -d '(' -f 2 | cut -d ')' -f 1 | awk -F ',' '{print $2}')
    echo ${x_coordinate}
    echo ${y_coordinate}
    if [ ! -z "$x_coordinate" -a ! -z "$y_coordinate" ]; then
      adb -s 48db50a5b827 shell input tap ${x_coordinate} ${y_coordinate}
    else
      break
    fi
    let "i=i+1"
  done

  # 分别左右滑动跳过介绍页
  echo "======从右向左滑动======"
  i=0
  while [[ ${i} -lt 8 ]]; do
    dump -c 48db50a5b827
    adb -s 48db50a5b827 shell input swipe 650 340 120 340 1000
    sleep 1
    let "i=i+1"
  done

#  i=0
#  while [[ ${i} -lt 8 ]]; do
#    dump -c 48db50a5b827s
#    adb -s 48db50a5b827 shell input swipe 157 306 622 346 1000
#    sleep 1
#    let "i=i+1"
#  done
  echo "完成授权和滑动后的页面"
  i=0
  while [[ ${i} -lt 10 ]]; do
    dump -c 48db50a5b827 > ./apk_temp/index_screen.log
    sleep 2
    dos2unix ./apk_temp/index_screen.log
    cat ./apk_temp/index_screen.log
    x_coordinate=$(cat ./apk_temp/index_screen.log | egrep '[[:space:]]允许[[:space:]]|[[:space:]]确认[[:space:]]|[[:space:]]已阅读并同意[[:space:]]|[[:space:]]同意并授权[[:space:]]|[[:space:]]跳过[[:space:]]|[[:space:]]接受[[:space:]]|[[:space:]]同意[[:space:]]|[[:space:]]继续[[:space:]]|[[:space:]]确定[[:space:]]|[[:space:]]开始使用[[:space:]]|[[:space:]]同意并继续[[:space:]]|[[:space:]]开始体验[[:space:]]|[[:space:]]立即体验[[:space:]]|[[:space:]]马上体验[[:space:]]' | cut -d '(' -f 2 | cut -d ')' -f 1 | awk -F ',' '{print $1}')
    y_coordinate=$(cat ./apk_temp/index_screen.log | egrep '[[:space:]]允许[[:space:]]|[[:space:]]确认[[:space:]]|[[:space:]]已阅读并同意[[:space:]]|[[:space:]]同意并授权[[:space:]]|[[:space:]]跳过[[:space:]]|[[:space:]]接受[[:space:]]|[[:space:]]同意[[:space:]]|[[:space:]]继续[[:space:]]|[[:space:]]确定[[:space:]]|[[:space:]]开始使用[[:space:]]|[[:space:]]同意并继续[[:space:]]|[[:space:]]开始体验[[:space:]]|[[:space:]]立即体验[[:space:]]|[[:space:]]马上体验[[:space:]]' | cut -d '(' -f 2 | cut -d ')' -f 1 | awk -F ',' '{print $2}')
    echo ${x_coordinate}
    echo ${y_coordinate}
    if [ ! -z "$x_coordinate" -a ! -z "$y_coordinate" ]; then
      adb -s 48db50a5b827 shell input tap ${x_coordinate} ${y_coordinate}
    else
      break
    fi
    let "i=i+1"

  done

  # 滑动完成后无法获知现在屏幕处于哪个页面，所以重启进入主界面
  # adb -s 48db50a5b827 shell am force-stop ${package_name}
  # sleep 2
  # adb -s 48db50a5b827 shell am start -n ${package_name}/${launchable_activity}
  # sleep 5


  # echo "======授权和滑动操作后的界面======"
  # dump -c 48db50a5b827
  # 此时需要检查是否还会出现滑动页面，并且此时还可能有其他弹窗

  # i=0
  # while [[ ${i} -lt 10 ]]; do
  #   dump -c 48db50a5b827 > ./apk_temp/index_screen.log
  #   sleep 2
  #   dos2unix ./apk_temp/index_screen.log
  #   cat ./apk_temp/index_screen.log
  #   x_coordinate=$(cat ./apk_temp/index_screen.log | egrep '允许|确认|已阅读并同意|同意并授权|跳过|接受|同意|继续|确定|开始使用|同意并继续|开始体验|立即体验|马上体验' | cut -d '(' -f 2 | cut -d ')' -f 1 | awk -F ',' '{print $1}')
  #   y_coordinate=$(cat ./apk_temp/index_screen.log | egrep '允许|确认|已阅读并同意|同意并授权|跳过|接受|同意|继续|确定|开始使用|同意并继续|开始体验|立即体验|马上体验' | cut -d '(' -f 2 | cut -d ')' -f 1 | awk -F ',' '{print $2}')
  #   echo ${x_coordinate}
  #   echo ${y_coordinate}
  #   if [ ! -z "$x_coordinate" -a ! -z "$y_coordinate" ]; then
  #     adb -s 48db50a5b827 shell input tap ${x_coordinate} ${y_coordinate}
  #   else
  #     break
  #   fi
  #   let "i=i+1"
  #
  # done

  echo "======APK主界面======"
  dump -c 48db50a5b827

  adb -s 48db50a5b827 uninstall ${package_name}
  sleep 5
  echo "======卸载APK后的界面======"
  dump -c 48db50a5b827

  adb -s 48db50a5b827 shell input keyevent 4
  adb -s 48db50a5b827 shell input keyevent 4
  adb -s 48db50a5b827 shell input keyevent 4
  adb -s 48db50a5b827 shell input keyevent 4

  dump -c 48db50a5b827
  sleep 2

  end_time=`date "+%s"`
  run_time=$((end_time-begin_time))
  echo "总运行时间: "${run_time}
  run_time_sleep=$((end_time-begin_time-25))
  echo "执行命令时间: "${run_time_sleep}

done
