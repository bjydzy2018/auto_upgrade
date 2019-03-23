#!/bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)

source ${CURRENT_PATH}/common_dep_util.sh

readonly LOG_FILE_NAME_PREFIX=`echo $(basename ${CLASS_NAME} .sh)`
LOG_FILE_NAME=${DATA_MODEL_SERVICE_NAME}_${LOG_FILE_NAME_PREFIX}.log
# 初始化日志
initLog ${DATA_MODEL_SERVICE_NAME} ${LOG_FILE_NAME}

# ----------------------------------------------------------------------
# FunctionName:		main
# createTime  :		2018-08-24
# description :		进程启动程序主函数入口
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    # 数据模型服务不涉及卸载组件，直接返回成功
    return 0
}

main $*