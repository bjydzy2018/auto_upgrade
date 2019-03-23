#!/bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)

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
# description :		进程启动程序主函数入口
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    # 启动接口服务
    ${DEPLOY_PATH}/bin/launcher start >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    [ $? -ne 0 ] && return 1
    
    return 0
}

main $*