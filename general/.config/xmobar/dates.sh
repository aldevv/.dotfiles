#!/bin/bash
declare -A days
days[Mon]="月"
days[Tue]="火"
days[Wed]="水"
days[Thu]="木"
days[Fri]="金"
days[Sat]="土"
days[Sun]="日"

day=$(LC_TIME="en_US.UTF-8" date +'%a')
date=$(date +"%d日%m月%y年 (${days[${day}]})")

echo "$date"
