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
for line in `cat apk_url.txt`
do
    begin_time=`date "+%s"`
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
#    echo ${#is_install}

    if [ ${#is_install} == 0 ]; then
        adb -s 48db50a5b827 install ./apk_temp/temp.apk > /dev/null 2>&1
    fi

    is_install=`adb -s 48db50a5b827 shell pm list packages -f | grep ${package_name}`
#    echo ${#is_install}
    if [ ${#is_install} != 0 ]; then
        echo "======APK安装成功======"
    else
        echo "?????APK安装失败?????"
        adb -s 48db50a5b827 uninstall ${package_name}
        continue
    fi

    echo "======强制重启APK======"
    adb -s 48db50a5b827 shell am force-stop ${package_name}
    sleep 1
    adb -s 48db50a5b827 shell am start -n ${package_name}/${launchable_activity}
    sleep 1

    # 1、判断屏幕是否睡眠 adb -s 48db50a5b827 shell cat /sys/power/state 需要root
    # 2、唤醒屏幕 adb -s 48db50a5b827 shell input keyevent 26
    # 3、滑屏 adb shell input swipe 120 700 510 700 500
    # 4、第一次有可能有授权设置
    # 5、第一次有可能有介绍页面
    # 6、介绍页面过后可能有欢迎页面
    # 7、检查登录

    echo "======第一次运行APK授权======"
    dump -c 48db50a5b827
    sleep 2
    is_alert=`dump -c 48db50a5b827 | grep 'alertTitle'`
    while [[ ${#is_alert} != 0 ]]
    do
        adb -s 48db50a5b827 shell input tap 502 757
        is_alert=`dump -c 48db50a5b827 | grep 'alertTitle'`
        sleep 2
    done

    echo "======强制重启APK跳过介绍页面======"
    adb -s 48db50a5b827 shell am force-stop ${package_name}
    sleep 1
    adb -s 48db50a5b827 shell am start -n ${package_name}/${launchable_activity}
    sleep 1

    echo "======获取登录界面======"
    dump -c 48db50a5b827
    sleep 3
    is_login=`dump -c 48db50a5b827 | grep "登录"`
    if [ ${#is_login} != 0 ]; then
        adb -s 48db50a5b827 uninstall ${package_name}
        continue
    fi

    echo "======正式运行APK主界面======"
    dump -c 48db50a5b827
    sleep 3
    dump -c 48db50a5b827 | grep "TextView" | awk -F '\n' '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1 | awk -F ', ' '{print $1,$2}' > ./apk_temp/coordinate.log

    dos2unix ./apk_temp/coordinate.log
#    cat ./apk_temp/coordinate.log
    x_coordinate=(`awk '{print $1}' ./apk_temp/coordinate.log`)
    y_coordinate=(`awk '{print $2}' ./apk_temp/coordinate.log`)

    i=0
    while [[ "$i" -lt ${#x_coordinate[*]} ]]
    do
         echo "adb -s 48db50a5b827 shell input tap "${x_coordinate[${i}]}" "${y_coordinate[${i}]}

         adb -s 48db50a5b827 shell input tap ${x_coordinate[${i}]} ${y_coordinate[${i}]}
         sleep 5
         adb -s 48db50a5b827 shell input keyevent 4
         sleep 5

         let "i=i+1"

    done

    adb -s 48db50a5b827 uninstall ${package_name}

    sleep 1
    end_time=`date "+%s"`
    run_time=$((end_time-begin_time))
    echo "总运行时间: "${run_time}
    run_time_sleep=$((end_time-begin_time-25))
    echo "执行命令时间: "${run_time_sleep}

done
