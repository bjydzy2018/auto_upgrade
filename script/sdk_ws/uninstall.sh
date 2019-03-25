#!/bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)

source ${CURRENT_PATH}/common_dep_util.sh

readonly LOG_FILE_NAME_PREFIX=`echo $(basename ${CLASS_NAME} .sh)`
LOG_FILE_NAME=${SDK_WS_NAME}_${LOG_FILE_NAME_PREFIX}.log
# 初始化日志
initLog ${SDK_WS_NAME} ${LOG_FILE_NAME}

# 组件新部署目录
readonly DEPLOY_PATH=${DEPLOY_ROOT_PATH}/${MICRO_SERVICE_NAME}/${SDK_WS_NAME}

# ----------------------------------------------------------------------
# FunctionName:		main
# createTime  :		2018-08-24
# description :		组件卸载主函数入口
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    if [ x"$1" = x"old" ]; then
        # 新版本组件卸载
        uninstall_old
        [ $? -ne 0 ] && return 1
    elif [ x"$1" = x"new" ]; then
        # 新版本组件卸载
        uninstall_new
        [ $? -ne 0 ] && return 1
    else
        # 老版本组件卸载
        uninstall_old
        [ $? -ne 0 ] && return 1
        
        # 新版本组件卸载
        uninstall_new
        [ $? -ne 0 ] && return 1
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		uninstall_old
# createTime  :		2018-08-27
# description :		老版本组件卸载
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function uninstall_old()
{
    printMessageLog INFO "uninstall old sdk ws starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    local deployPath=""

    # 目录不存在，不需要卸载，未安装，直接返回成功
    if [ ! -d ${SDK_WS_DEPLOY_PATH} ]; then
        return 0
    fi
    
    # 获取老接口服务目录
    local services=$(ls -l ${SDK_WS_DEPLOY_PATH} | grep "sdk_ws" | awk '/^d/ {print $NF}')
    if [ -z ${services} ]; then
        services=$(ls -l ${SDK_WS_DEPLOY_PATH} | grep "sdk-ws" | awk '/^d/ {print $NF}')
        if [ -z ${services} ]; then
            services=$(ls -l ${SDK_WS_DEPLOY_PATH} | grep "queryframework" | awk '/^d/ {print $NF}')
            if [ -z ${services} ]; then
                return 0
            fi
        fi
    fi
    
    for service in ${services[@]}
    do
        # 先备份整个目录
        backup_directory ${SDK_WS_DEPLOY_PATH} ${service}
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "backup ${SDK_WS_DEPLOY_PATH}/${service} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
    
        # 再删除已有目录
        deployPath=${SDK_WS_DEPLOY_PATH}/${service}
        rm -rf ${deployPath} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "rm -rf ${deployPath} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
    done
    
    
    
    printMessageLog INFO "uninstall old sdk ws end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		uninstall_new
# createTime  :		2018-08-27
# description :		新版本组件卸载
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function uninstall_new()
{
    printMessageLog INFO "uninstall sdk ws starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 新版本组件卸载
    if [ ! -d ${DEPLOY_PATH} ]; then
        return 0
    fi
    
    # 先备份整个目录
    backup_directory ${DEPLOY_ROOT_PATH}/${MICRO_SERVICE_NAME} ${SDK_WS_NAME}
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "backup ${DEPLOY_ROOT_PATH}/${MICRO_SERVICE_NAME}/${SDK_WS_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 再删除目录
    rm -rf ${DEPLOY_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "Uninstall an new version of the component [${SDK_WS_NAME}] failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog INFO "uninstall sdk ws end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

main $*