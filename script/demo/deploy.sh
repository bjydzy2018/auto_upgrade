#!/bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)
COMPENENT_NAME="report_system"

LOG_FILE_PATH=/var/log/sdk_vbs/script
LOG_FILE_NAME_PREFIX=`echo $(basename ${CLASS_NAME} .sh)`
LOG_FILE_NAME=${COMPENENT_NAME}_${LOG_FILE_NAME_PREFIX}.log

source ${CURRENT_PATH}/common_dep_util.sh
initLog ${LOG_FILE_PATH} ${LOG_FILE_NAME}

# ----------------------------------------------------------------------
# FunctionName:        main
# createTime  :        2018-08-10
# description :        组件部署函数入口
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    local type=$1

    # 读取部署参数，若时本地安装，使用默认参数
    if [ x"${type}" == x"manual" ]; then
        defaultParams
        [ $? -ne 0 ] && return 1
    else
        readParams
        [ $? -ne 0 ] && return 1
    fi

    # 部署参数校验
    paramsCheck
    [ $? -ne 0 ] && return 1

    # 部署预检查
    preCheck
    [ $? -ne 0 ] && return 1

    # 若有老版本，先停止
    stop
    [ $? -ne 0 ] && return 1

    # 若有老版本，先卸载
    uninstall
    [ $? -ne 0 ] && return 1

    # 安装，配置文件修改
    install
    [ $? -ne 0 ] && return 1

    # 启动进程
    start
    [ $? -ne 0 ] && return 1

    # 启动后检查健康状态
    postCheck
    [ $? -ne 0 ] && return 1

    # 部署成功后备份部署包
    backupPackage
    [ $? -ne 0 ] && return 1

    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        defaultParams
# createTime  :        2018-08-10
# description :        本地测试默认参数处理
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function defaultParams()
{
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        readParams
# createTime  :        2018-08-10
# description :        组件部署参数读取
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function readParams()
{
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        paramsCheck
# createTime  :        2018-08-10
# description :        组件部署参数校验
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function paramsCheck()
{
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        preCheck
# createTime  :        2018-08-10
# description :        组件部署前依赖校验
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function preCheck()
{
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        stop
# createTime  :        2018-08-10
# description :        组件进程停止
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function stop()
{
    sh ${CURRENT_PATH}/stop.sh

    if [ $? -ne 0 ]; then
        printMessageLog ERROR "stop ${COMPENENT_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog INFO "stop ${COMPENENT_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        uninstall
# createTime  :        2018-08-10
# description :        组件卸载
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function uninstall()
{
    sh ${CURRENT_PATH}/uninstall.sh

    if [ $? -ne 0 ]; then
        printMessageLog ERROR "uninstall ${COMPENENT_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog INFO "uninstall ${COMPENENT_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        install
# createTime  :        2018-08-10
# description :        组件安装
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function install()
{
    sh ${CURRENT_PATH}/install.sh

    if [ $? -ne 0 ]; then
        printMessageLog ERROR "install ${COMPENENT_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog INFO "install ${COMPENENT_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        start
# createTime  :        2018-08-10
# description :        组件进程启动
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function start()
{
    sh ${CURRENT_PATH}/start.sh start

    if [ $? -ne 0 ]; then
        printMessageLog ERROR "start ${COMPENENT_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog INFO "start ${COMPENENT_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        postCheck
# createTime  :        2018-08-10
# description :        组件部署后检查
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function postCheck()
{
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        backupPackage
# createTime  :        2018-08-10
# description :        组件部署成功后备份部署包，用于回滚
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function backupPackage()
{
    return 0
}

main $*

if [ $? -ne 0 ]; then 
    printMessageLog ERROR "${COMPENENT_NAME} deploy failed." ${FUNCNAME} ${LINENO}
    exit 1
else
    printMessageLog INFO "${COMPENENT_NAME} deploy successfully." ${FUNCNAME} ${LINENO}
    exit 0
fi
