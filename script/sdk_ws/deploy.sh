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
# FunctionName:        main
# createTime  :        2018-08-23
# description :        组件部署函数入口
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    # 显示标志
    showBanner
    
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
    sleep 10

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
# description :        组件部署前依赖校验
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function preCheck()
{
    printMessageLog WARN "preCheck ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
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
   
    # Java安装判断
    isExistJRE
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "Java is not installed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 部署路径校验
    if [ ! -d ${DEPLOY_PATH} ]; then
        printMessageLog WARN "deploy directory [${DEPLOY_PATH}] is not existed, create it." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        mkdir -p ${DEPLOY_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        chmod -R 755 ${DEPLOY_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    fi
    
    # 备份路径校验
    if [ ! -d ${BACKUP_ROOT_PATH}/${SDK_WS_NAME} ]; then
        printMessageLog WARN "deploy directory [${BACKUP_ROOT_PATH}/${SDK_WS_NAME}] is not existed, create it." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        mkdir -p ${BACKUP_ROOT_PATH}/${SDK_WS_NAME}/config >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        chmod -R 755 ${BACKUP_ROOT_PATH}/${SDK_WS_NAME}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    fi
    
    printMessageLog WARN "preCheck ${SDK_WS_NAME} end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog WARN "defaultParams ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog WARN "readParams ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
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
    printMessageLog WARN "paramsCheck ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 公共参数校验
    if [ -z ${ES_HOST} ]; then
        printMessageLog ERROR "the parameter [ES_HOST] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${ES_TCP_HOST} ]; then
        printMessageLog ERROR "the parameter [ES_TCP_HOST] is null, use default value [9200]." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        ES_TCP_HOST="9200"
    fi

    if [ -z ${ES_HTTP_HOST} ]; then
        printMessageLog ERROR "the parameter [ES_HTTP_HOST] is null, use default value [9300]." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        ES_HTTP_HOST="9300"
    fi

    if [ -z ${ES_CLUSTER_NAME} ]; then
        printMessageLog ERROR "the parameter [ES_CLUSTER_NAME] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${NN_REDIS_HOST} ]; then
        printMessageLog ERROR "the parameter [NL_CMS_DB_NAME] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${NN_REDIS_PORT} ]; then
        printMessageLog ERROR "the parameter [NN_REDIS_PORT] is null, use default value [6379]." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        NN_REDIS_PORT="6379"
    fi
    
    if [ -z ${NEO4J_URL} ]; then
        printMessageLog ERROR "the parameter [NEO4J_URL] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${KYLIN_URL} ]; then
        printMessageLog ERROR "the parameter [KYLIN_URL] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${KYLIN_USER} ]; then
        printMessageLog ERROR "the parameter [KYLIN_USER] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${KYLIN_PASSWORD} ]; then
        printMessageLog ERROR "the parameter [KYLIN_PASSWORD] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    # 组件参数校验
    if [ -z ${GRAPHX_URL} ]; then
        printMessageLog ERROR "the parameter [GRAPHX_URL] is null." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi

    if [ -z ${PRESTO_URL} ]; then
        printMessageLog ERROR "the parameter [PRESTO_URL] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        isStartWith ${PRESTO_URL} "jdbc:presto"
        if [ $? -ne 0 ]; then
            PRESTO_URL="jdbc:presto://"${PRESTO_URL}"/hive/default"
        fi
    fi

    if [ -z ${PRESTO_USER} ]; then
        printMessageLog ERROR "the parameter [PRESTO_USER] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ ! -z ${PRESTO_PASSWD} ]; then
        printMessageLog WARN "the parameter [PRESTO_PASSWD:${PRESTO_PASSWD}] is not null, please check." ${CLASS_NAME} ${FUNCNAME} ${LINENO} ${RED_COLOR}
        readInput
        [[ $? -ne 0 ]] && return 1
    fi
    
    if [ -z ${DEFAULT_PLATFORM_ID} ]; then
        printMessageLog WARN "the parameter [DEFAULT_PLATFORM_ID] is null, use default value [default]." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        DEFAULT_PLATFORM_ID="default"
    elif [ x"default" != x"${DEFAULT_PLATFORM_ID}" ]; then
        printMessageLog WARN "the parameter [DEFAULT_PLATFORM_ID] is not default, please check." ${CLASS_NAME} ${FUNCNAME} ${LINENO} ${RED_COLOR}
        readInput
        [[ $? -ne 0 ]] && return 1
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
    printMessageLog WARN "stop ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/stop.sh
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "stop ${SDK_WS_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog WARN "stop ${SDK_WS_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog WARN "uninstall ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/uninstall.sh
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "uninstall ${SDK_WS_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog WARN "uninstall ${SDK_WS_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog WARN "install ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/install.sh "deploy"
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "install ${SDK_WS_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog WARN "install ${SDK_WS_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog WARN "start ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/start.sh "deploy"
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "start ${SDK_WS_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog WARN "start ${SDK_WS_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog WARN "postCheck ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 校验接口服务进程是否存在
    local status=$(jps | grep QueryProxyWebServer)
    if [ -z "${status}" ]; then
        printMessageLog ERROR "QueryProxyWebServer haven't start." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog WARN "process info is: ${status}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog WARN "backupComponentPackage ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    backupPackage ${SDK_WS_NAME}
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "backup package failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog WARN "backup package successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

main $*

if [ $? -ne 0 ]; then 
    printMessageLog ERROR "${SDK_WS_NAME} deploy failed." ${FUNCNAME} ${LINENO}
    exit 1
else
    printMessageLog INFO "${SDK_WS_NAME} deploy successfully." ${FUNCNAME} ${LINENO}
    exit 0
fi
