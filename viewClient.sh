#!/usr/bin/env bash

set -x

# 手机设置
# 开发者选项连接USB
# [设置]->[显示]->[休眠]，最长时间休眠
# 开始屏幕最好只有一页，不强求
# ROOT

#1、下载
#2、解包获取包名
#3、检查是否安装，没有安装就安装
#4、检查安装是否成功
#5、检查是否运行，停止运行，重新运行
#6、获取屏幕控件信息

dos2unix apk_url.txt
for line in `cat apk_url.txt`
do
    if [ -e ./apk_temp ]; then
        rm -rf ./apk_temp
        mkdir ./apk_temp
    else
        mkdir ./apk_temp
    fi

    echo ${line}
    wget ${line} -O ./apk_temp/temp.apk
#    apk_info=`aapt dump badging ./apk_temp/temp.apk`
#    echo ${apk_info}
#    package_name=`echo ${apk_info} | grep "package: name="`
#    echo ${package_name}
    aapt dump badging ./apk_temp/temp.apk > ./apk_temp/apk_info.log
    if [ $? -gt 0 ]; then
        continue
    fi

    package_name=`cat ./apk_temp/apk_info.log | grep "package: name" | awk '{print $2}' | cut -d "'" -f 2`
#    package_name=`echo -n ${package_name}`
    echo ${package_name}
    launchable_activity=`cat ./apk_temp/apk_info.log | grep "launchable-activity: name" | awk '{print $2}' | cut -d "'" -f 2`
#    launchable_activity=`echo -n ${launchable_activity}`
    echo ${launchable_activity}

    is_install=`adb -s 48db50a5b827 shell pm list packages -f | grep ${package_name}`
    echo ${is_install}
    echo ${#is_install}

    if [ ${#is_install} == 0 ]; then
        adb -s 48db50a5b827 install ./apk_temp/temp.apk
    fi

    is_install=`adb -s 48db50a5b827 shell pm list packages -f | grep ${package_name}`
    echo ${is_install}
    echo ${#is_install}

    is_running=`adb -s 48db50a5b827 shell ps | grep ${package_name}`
    echo ${is_running}
    echo ${#is_running}

    if [ ${#is_running} == 0 ]; then
        adb -s 48db50a5b827 shell am start -n ${package_name}/${launchable_activity}
    else
        # 不能直接杀死进程，需要root
        adb -s 48db50a5b827 shell am force-stop ${package_name}
        adb -s 48db50a5b827 shell am start -n ${package_name}/${launchable_activity}
    fi

    is_running=`adb -s 48db50a5b827 shell ps | grep ${package_name}`
    echo ${is_running}
    echo ${#is_running}

    # 1、判断屏幕是否睡眠 adb -s 48db50a5b827 shell cat /sys/power/state 需要root
    # 2、唤醒屏幕 adb -s 48db50a5b827 shell input keyevent 26
    # 3、滑屏 adb shell input swipe 120 700 510 700 500
    # 4、第一次有可能有授权设置
    # 5、第一次有可能有介绍页面
    # 6、介绍页面过后可能有欢迎页面
    # 7、检查登录

    is_alert=`dump -c 48db50a5b827 | grep 'alertTitle'`
    while [[ ${#is_alert} != 0 ]]
    do
        adb -s 48db50a5b827 shell input tap 502 757
        is_alert=`dump -c 48db50a5b827 | grep 'alertTitle'`
    done

    # 第二次运行就没有介绍页面了，所以先停止应用，再开始应用
    adb -s 48db50a5b827 shell am force-stop ${package_name}
    adb -s 48db50a5b827 shell am start -n ${package_name}/${launchable_activity}
#    introduction_count=0
#    is_introduce=`dump -c 48db50a5b827 | grep 'FrameLayout'`
#    while [[ ${#is_introduce} != 0 ]]
#    do
#        adb shell input swipe 510 700 120 700 500
#        sleep 5
#        let "introduction_count=introduction_count+1"
#        if [ ${introduction_count} -gt 10 ]; then
#            break
#        fi
#        is_introduce=`dump -c 48db50a5b827 | grep 'FrameLayout'`
#    done


    is_login=`dump -c 48db50a5b827 | grep "登录"`
    if [ ${#is_login} != 0 ]; then
        adb -s 48db50a5b827 uninstall ${package_name}
        continue
    fi

    dump -c 48db50a5b827
    dump -c 48db50a5b827 | grep "TextView" | awk -F '\n' '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1 | awk -F ', ' '{print $1,$2}' > ./apk_temp/coordinate.log
#    dump -c 48db50a5b827 | grep "TextView" | cut -d '(' -f 2 | cut -d ')' -f 1 > ./apk_temp/coordinate.log
#    dump -c 48db50a5b827 | grep "TextView" > ./apk_temp/coordinate.log

    cat ./apk_temp/coordinate.log | while read coordinate
    do
        echo ${coordinate}
        adb -s 48db50a5b827 shell input tap ${coordinate}
        sleep 2
        adb -s 48db50a5b827 shell input keyevent 4

    done

#    adb -s 48db50a5b827 uninstall ${package_name}

    sleep 3

done


