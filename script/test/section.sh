#!/bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)

# crontab路径
readonly CRONTAB_PATH=/var/spool/cron/root


# ----------------------------------------------------------------------
# FunctionName:		setCrontab
# createTime  :		2018-08-24
# description :		crontab修改
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function setCrontab()
{
    
    # 文件格式标准化
    dos2unix ${CRONTAB_PATH}
    
    # 先判断
    local isExist=""
    CRONTAB_LIST=$(readSectionList param.ini "crontab_list")
    
    echo "${CRONTAB_LIST[@]}"
    
    # 配置的crontab列表
    if [ -z "${CRONTAB_LIST}" -o 0=${#CRONTAB_LIST[@]} ]; then
        echo "crontab list is null, no need to modify." 
        return 0
    fi
    
    # 将结果转换为数组
    
    
    # 遍历数组，分别写入crontab文件
    for list in ${CRONTAB_LIST[@]}
    do
        # 判断定时器任务是否存在，若存在，则不添加
        isExist=$(cat ${CRONTAB_PATH} | grep "${list}")
        if [ -z "${isExist}" ]; then
            echo "add crontab: ${list}"
        else
            echo "crontab list is null, no need to modify."
        fi
    done
    
    # 删除空行
    sed -i '/^$/d' ${CRONTAB_PATH}
    
    # 重启crontab
    service crond restart
    if [ $? -ne 0 ]; then
        echo "service crond restart failed."
    else    
        echo "service crond restart successfully."
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		readSectionList
# createTime  :		2019-03-11
# description :		读取ini文件中某个section的所有值
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function readSectionList()
{
    if [ $# -lt 2 ]; then
        echo "parameter is invalid, at least 2 parameters, which contain file path and section."
        exit 1
    fi
    local iniFilePath=$1
    local section=$2
    
    if [ ! -f ${iniFilePath} ]; then
        echo "File ${iniFilePath} is not exist."
        exit 1
    fi

    echo "sed -n \"/\[${section}\]/,/\[.*\]/p\" ${iniFilePath} | grep -v \"\[.*\]\" | awk -F'=' '{print $1}' | sed 'N;$!P;D' | sed '$d'"
    local valueList=$(sed -n "/\[${section}\]/,/\[.*\]/p" ${iniFilePath} | grep -v "\[.*\]" | awk -F'=' '{print $1}' | sed 'N;$!P;D' | sed '$d')

    echo "${valueList}"
}

setCrontab $*
