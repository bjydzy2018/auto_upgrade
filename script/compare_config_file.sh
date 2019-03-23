#!/bin/bash

CONFIG_WHITE_LIST=(permission2 cname passwd duanwf)

# ----------------------------------------------------------------------
# FunctionName:        main
# createTime  :        2018-08-23
# description :        入口
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    local file1=$1
    local file2=$2
    
    while read line; do
        key=`echo $line|awk -F '=' '{print $1}'`
        value=`echo $line|awk -F '=' '{print $2}'`
        
        # 跳过空行
        if [ -z "${key}" ]; then
            continue
        fi
        
        # 跳过注释
        isStartWith "${key}" "#"
        if [ $? -eq 0 ]; then
            continue
        fi
        
        # 跳过白名单
        if echo "${CONFIG_WHITE_LIST[@]}" | grep -w "${key}" &>/dev/null; then
            echo "white_${key}=${value}"
            continue
        fi
        
        echo "${key}=${value}"
        
        # 是否在文件2中
        local tmp=$(readConfig ${key} ${file2})
        if [ -z "${tmp}" ]; then
            echo "null"
        else
            echo "file2: ${key}=${tmp}"
        fi
        
    done < ${file1}
}

function readConfig()
{
    local key=$1
    local configFile=$2
    local value=

    if [ ! -f ${configFile} ];then
        echo ""
    fi
    
    value=`awk -F'=' '{if($1~/'${key}'/) print $2}' ${configFile}`

    echo ${value}
}

function isStartWith()
{
    local string=$1
    local start=$2

    if [[ "${string}" =~ ^${start}.* ]]; then
        return 0
    fi

    return 1
}

main $*