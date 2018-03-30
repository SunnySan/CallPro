#!/bin/bash

#前一個小時，例如：2018-03-27 17
one_hour_ago=`date "+%Y-%m-%d %H" -d '-1 hours'`

#前一個小時在CallPro.log裡面，錯誤(ERROR)記錄的筆數
count=`grep "$one_hour_ago" /opt/tomcat/logs/CallPro.log | grep -c ERROR`

if (($count>0)); then
    curl -s -o "/dev/null" --connect-timeout 10 --data-urlencode "message=系統告警：前一小時
($one_hour_ago)伺服器log檔中錯誤筆數共$count筆，請檢查系統是否正常。" http://www.call-pro.net/CallPro/ajaxSystem_SendAlarmNotification.jsp
fi
