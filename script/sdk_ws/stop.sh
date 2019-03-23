#!/bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)
PACKAGE_PATH=${CURRENT_PATH}/../

source ${CURRENT_PATH}/common_dep_util.sh

readonly LOG_FILE_NAME_PREFIX=`echo $(basename ${CLASS_NAME} .sh)`
LOG_FILE_NAME=${SDK_WS_NAME}_${LOG_FILE_NAME_PREFIX}.log
# 初始化日志
initLog ${SDK_WS_NAME} ${LOG_FILE_NAME}

# 组件部署目录
readonly DEPLOY_PATH=${DEPLOY_ROOT_PATH}/${MICRO_SERVICE_NAME}/${SDK_WS_NAME}

# ----------------------------------------------------------------------
# FunctionName:		main
# createTime  :		2018-08-24
# description :		进程停止程序主函数入口
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    if [ x"$1" = x"old" ]; then
        # 新版本组件卸载
        stop_old
        [ $? -ne 0 ] && return 1
    elif [ x"$1" = x"new" ]; then
        # 新版本组件卸载
        stop_new
        [ $? -ne 0 ] && return 1
    else
        # 老版本组件卸载
        stop_old
        [ $? -ne 0 ] && return 1
        
        # 新版本组件卸载
        stop_new
        [ $? -ne 0 ] && return 1
    fi
    
    # 强制kill进程，避免执行stop时失败
    killPids
    [ $? -ne 0 ] && return 1    
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		stop_new
# createTime  :		2018-08-27
# description :		新版本停止，需要遍历所有目录
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function stop_new()
{
    printMessageLog WARN "stop sdk ws process starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 文件不存在，不需要停止，未安装，直接返回成功
    if [ ! -f ${DEPLOY_PATH}/bin/launcher ]; then
        return 0
    fi
    
    ${DEPLOY_PATH}/bin/launcher stop >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1

    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		stop_old
# createTime  :		2018-08-27
# description :		遍历所有接口服务目录，执行停止进程操作
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function stop_old()
{
    printMessageLog WARN "stop old sdk ws process starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 目录不存在，不需要停止，未安装，直接返回成功
    if [ ! -d ${SDK_WS_DEPLOY_PATH} ]; then
        return 0
    fi
    
#    # 获取接口服务目录
#    local services=$(ls -l ${SDK_WS_DEPLOY_PATH} | grep "sdk_ws" | awk '/^d/ {print $NF}')
#    if [ -z ${services} ]; then
#        services=$(ls -l ${SDK_WS_DEPLOY_PATH} | grep "sdk-ws" | awk '/^d/ {print $NF}')
#        if [ -z ${services} ]; then
#            services=$(ls -l ${SDK_WS_DEPLOY_PATH} | grep "queryframework" | awk '/^d/ {print $NF}')
#            if [ -z ${services} ]; then
#                return 0
#            fi
#        fi
#    fi    
#    
#    for service in ${services[@]}
#    do
#        local launcherPath=${SDK_WS_DEPLOY_PATH}/${service}/bin/launcher
#        ${launcherPath} stop >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
#    done
    
    local pids=$(jps | grep "QueryProxyWebServer" | awk '{print $1}')
    [[ -z "${pids}" ]] && return 0
    
    for pid in ${pids[@]}
    do
        kill -9 ${pid}
    done
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		killPids
# createTime  :		2018-08-27
# description :		强制kill进程号
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function killPids()
{
    printMessageLog WARN "kill sdk ws process starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 获取接口服务进程号
    local pidNum=$(jps | grep QueryProxyWebServer | awk '{print $1}')
    if [ -z ${pidNum} ]; then
        return 0
    fi
    
    for pid in ${pidNum[@]}
    do
        if [ -z ${pidNum} ]; then
            kill -9 ${pid} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
            if [ $? -ne 0 ]; then
                printMessageLog WARN "kill -9 ${pid} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
                return 1
            else
                printMessageLog WARN "kill -9 ${pid} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            fi
        fi
    done
    
    return 0
}

main $*
