#!/bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)
PACKAGE_PATH=${CURRENT_PATH}/../

source ${CURRENT_PATH}/common_dep_util.sh

readonly LOG_FILE_NAME_PREFIX=`echo $(basename ${CLASS_NAME} .sh)`
LOG_FILE_NAME=${DATA_MODEL_SERVICE_NAME}_${LOG_FILE_NAME_PREFIX}.log
# 初始化日志
initLog ${DATA_MODEL_SERVICE_NAME} ${LOG_FILE_NAME}

# 组件部署目录
readonly DEPLOY_PATH=${DEPLOY_ROOT_PATH}/${MICRO_SERVICE_NAME}/${DATA_MODEL_SERVICE_NAME}

# ----------------------------------------------------------------------
# FunctionName:        main
# createTime  :        2018-08-23
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
    
    # 部署预检查
    preCheck
    [ $? -ne 0 ] && return 1
    
    # 部署参数校验
    paramsCheck
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
    backupComponentPackage
    [ $? -ne 0 ] && return 1

    return 0
}


# ----------------------------------------------------------------------
# FunctionName:        preCheck
# createTime  :        2018-08-23
# description :        组件部署前依赖校验，暂不校验蓝鲸平台
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function preCheck()
{
    printMessageLog INFO "preCheck ${DATA_MODEL_SERVICE_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 常用linux命令检查
    isExistDos2unix
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "dos2unix is not installed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    isExistUnzip
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "unzip is not installed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    isExistRsync
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "rsync is not installed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi 
    
    # 是否安装MySQL
    isExistMySQL ${CLUSTER_MYQL_DB_HOST} ${CLUSTER_MYQL_DB_USER} ${CLUSTER_MYQL_DB_PASSWD}
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "MySQL connection failed, host=${CLUSTER_MYQL_DB_HOST}, username=${CLUSTER_MYQL_DB_USER}, passwd=${CLUSTER_MYQL_DB_PASSWD}." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 是否安装Hive
    isExistHive ${HIVE_PLATFORM_ID}
    [[ $? -ne 0 ]] && return 1
    
    # 是否安装蓝鲸调度平台
#    isExistBluewhale
#    if [ $? -ne 0 ]; then
#        return 1
#    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        defaultParams
# createTime  :        2018-08-23
# description :        本地测试默认参数处理
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function defaultParams()
{
    printMessageLog INFO "defaultParams ${DATA_MODEL_SERVICE_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    cat ${DEFAULT_DEPLOY_FILE_PATH} > ${DEPLOY_FILE_PATH}
    readParams
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        readParams
# createTime  :        2018-08-23
# description :        组件部署参数读取
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function readParams()
{
    printMessageLog INFO "readParams ${DATA_MODEL_SERVICE_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 读取部署参数
    readDeployParams
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        paramsCheck
# createTime  :        2018-08-23
# description :        组件部署参数校验
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function paramsCheck()
{
    if [ -z ${NL_DB_HOST} ]; then
        printMessageLog ERROR "the parameter [NL_DB_HOST] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${NL_DB_USER} ]; then
        printMessageLog ERROR "the parameter [NL_DB_USER] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${NL_DB_PASS} ]; then
        printMessageLog ERROR "the parameter [NL_DB_PASS] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${BW_MYQL_DB_HOST} ]; then
        printMessageLog ERROR "the parameter [BW_MYQL_DB_HOST] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${BW_MYQL_DB_USER} ]; then
        printMessageLog ERROR "the parameter [BW_MYQL_DB_USER] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${BW_MYQL_DB_PASSWD} ]; then
        printMessageLog ERROR "the parameter [BW_MYQL_DB_PASSWD] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${BW_MYQL_DB_DBNAME} ]; then
        printMessageLog ERROR "the parameter [BW_MYQL_DB_DBNAME] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${CLUSTER_MYQL_DB_HOST} ]; then
        printMessageLog ERROR "the parameter [CLUSTER_MYQL_DB_HOST] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${CLUSTER_MYQL_DB_USER} ]; then
        printMessageLog ERROR "the parameter [CLUSTER_MYQL_DB_USER] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${CLUSTER_MYQL_DB_PASSWD} ]; then
        printMessageLog ERROR "the parameter [CLUSTER_MYQL_DB_PASSWD] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${CLUSTER_MYQL_DB_DBNAME} ]; then
        printMessageLog ERROR "the parameter [CLUSTER_MYQL_DB_DBNAME] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${HIVE_PLATFORM_ID} ]; then
        printMessageLog ERROR "the parameter [HIVE_PLATFORM_ID] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        stop
# createTime  :        2018-08-24
# description :        组件进程停止
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function stop()
{
    printMessageLog INFO "stop ${DATA_MODEL_SERVICE_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/stop.sh
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "stop ${DATA_MODEL_SERVICE_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog INFO "stop ${DATA_MODEL_SERVICE_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        uninstall
# createTime  :        2018-08-23
# description :        组件卸载
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function uninstall()
{
    printMessageLog INFO "uninstall ${DATA_MODEL_SERVICE_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/uninstall.sh
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "uninstall ${DATA_MODEL_SERVICE_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog INFO "uninstall ${DATA_MODEL_SERVICE_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        install
# createTime  :        2018-08-23
# description :        组件安装
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function install()
{
    printMessageLog INFO "install ${DATA_MODEL_SERVICE_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/install.sh "deploy"
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "install ${DATA_MODEL_SERVICE_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog INFO "install ${DATA_MODEL_SERVICE_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        start
# createTime  :        2018-08-23
# description :        组件进程启动
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function start()
{
    printMessageLog INFO "start ${DATA_MODEL_SERVICE_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/start.sh
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "start ${DATA_MODEL_SERVICE_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog INFO "start ${DATA_MODEL_SERVICE_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        postCheck
# createTime  :        2018-08-23
# description :        组件部署后检查
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function postCheck()
{
    # 数据模型服务不涉及校验组件，直接返回成功
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        backupComponentPackage
# createTime  :        2018-08-23
# description :        组件部署成功后备份部署包，用于回滚
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function backupComponentPackage()
{
    printMessageLog INFO "backupComponentPackage ${DATA_MODEL_SERVICE_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    backupPackage ${DATA_MODEL_SERVICE_NAME}
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "backup package failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog INFO "backup package successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

main $*

if [ $? -ne 0 ]; then 
    printMessageLog ERROR "${DATA_MODEL_SERVICE_NAME} deploy failed." ${FUNCNAME} ${LINENO}
    exit 1
else
    printMessageLog INFO "${DATA_MODEL_SERVICE_NAME} deploy successfully." ${FUNCNAME} ${LINENO}
    exit 0
fi
