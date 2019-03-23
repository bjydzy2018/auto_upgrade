#!/bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)

source ${CURRENT_PATH}/common_dep_util.sh

readonly LOG_FILE_NAME_PREFIX=`echo $(basename ${CLASS_NAME} .sh)`
LOG_FILE_NAME=${REPORTER_SYSTEM_NAME}_${LOG_FILE_NAME_PREFIX}.log
# 初始化日志
initLog ${REPORTER_SYSTEM_NAME} ${LOG_FILE_NAME}

# ----------------------------------------------------------------------
# FunctionName:		main
# createTime  :		2018-08-24
# description :		进程启动程序主函数入口
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    printMessageLog INFO "${NGINX_PATH}/sbin/nginx -s reload" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 报表平台部署完成后，需要重启nginx
    ${NGINX_PATH}/sbin/nginx -s reload >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    [ $? -ne 0 ] && return 1
    
    return 0
}

main $*