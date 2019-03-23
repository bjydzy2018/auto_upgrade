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
# sdkws.properties配置文件路径
ONLINE_SDKWS_CONFIG_FILE=""

# 线上环境版本号
ONLINE_VERSION_NUMBER=""

# 线上接口服务部署路径
ONLIE_DEPLOY_PATH=""

# 备份配置文件路径
readonly BACKUP_SDKWS_PATH=${BACKUP_ROOT_PATH}/${SDK_WS_NAME}
readonly BACKUP_CONFIG_PATH=${BACKUP_SDKWS_PATH}/config
readonly SDKWS_CONFIG_FILE_BACKUP_PATH=${BACKUP_CONFIG_PATH}/sdkws.properties
readonly BLUEWHALE_CONFIG_FILE_BACKUP_PATH=${BACKUP_CONFIG_PATH}/bluewhale-site.properties

# ----------------------------------------------------------------------
# FunctionName:        main
# createTime  :        2018-08-23
# description :        组件部署函数入口
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    # 备份配置文件
    backupConfig
    [ $? -ne 0 ] && return 1

    # 读取部署参数
    readParams
    [ $? -ne 0 ] && return 1

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
#    uninstall
#    [ $? -ne 0 ] && return 1

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
# description :        组件升级前依赖校验
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function preCheck()
{
    printMessageLog INFO "preCheck ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}

    # 常用linux命令检查
    isExistDos2unix
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "install dos2unix failed.." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    isExistUnzip
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "install unzip failed.." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        backupConfig
# createTime  :        2018-08-23
# description :        部署前原配置文件备份，用于配置项还原和回滚
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function backupConfig()
{
    printMessageLog INFO "backupConfig ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 获取当前环境接口服务版本号
    if [ -f ${DEPLOY_PATH}/version ]; then
        ONLINE_VERSION_NUMBER=$(getVersionNumber ${DEPLOY_PATH}/version)
        ONLINE_SDKWS_CONFIG_FILE=${DEPLOY_PATH}/apps/${ONLINE_VERSION_NUMBER}/conf/sdkws.properties
        ONLINE_BLUEWHALE_CONFIG_FILE=${DEPLOY_PATH}/conf/bluewhale-site.properties
        ONLIE_DEPLOY_PATH=${DEPLOY_PATH}
    elif [ -d ${SDK_WS_DEPLOY_PATH} ]; then
        # 取目录下最新的sdkws部署目录
        local onlineName=$(ls -lt ${SDK_WS_DEPLOY_PATH} | grep "sdk" | awk '/^d/ {print $NF}' | sed 's/ .*$//' | head -n 1)
        if [ -z ${onlineName} ]; then
            printMessageLog ERROR "${SDK_WS_DEPLOY_PATH} haven't install, please excute deploy." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            exit 0
        fi
        
        # 取最新版本号
        local onlineVersion=$(ls -lt ${SDK_WS_DEPLOY_PATH}/${onlineName}/apps/ | grep "v" | awk '/^d/ {print $NF}' | sed 's/ .*$//' | head -n 1)
        if [ -z ${onlineVersion} ]; then
            printMessageLog ERROR "${SDK_WS_DEPLOY_PATH} apps haven't install, please excute deploy." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            exit 0
        fi
        ONLINE_VERSION_NUMBER=${onlineVersion}
        
        # 拼接配置文件路径
        ONLINE_SDKWS_CONFIG_FILE=${SDK_WS_DEPLOY_PATH}/${onlineName}/apps/${onlineVersion}/conf/sdkws.properties
        ONLINE_BLUEWHALE_CONFIG_FILE=${SDK_WS_DEPLOY_PATH}/${onlineName}/conf/bluewhale-site.properties
        ONLIE_DEPLOY_PATH=${SDK_WS_DEPLOY_PATH}/${onlineName}
    else
        printMessageLog ERROR "${SDK_WS_DEPLOY_PATH} haven't install, please excute deploy." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        exit 0
    fi
    
    if [ ! -d ${BACKUP_CONFIG_PATH} ]; then
        printMessageLog ERROR "${BACKUP_CONFIG_PATH} is not existed, create it." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        mkdir -p ${BACKUP_CONFIG_PATH}  >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        chmod -R 755 ${BACKUP_CONFIG_PATH}
    fi
    
    # 备份sdkws.properties配置文件
    printMessageLog INFO "backup file: ${ONLINE_SDKWS_CONFIG_FILE}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    if [ -f ${ONLINE_SDKWS_CONFIG_FILE} ]; then
        rsync -a -r ${ONLINE_SDKWS_CONFIG_FILE} ${SDKWS_CONFIG_FILE_BACKUP_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    else 
        printMessageLog ERROR "${ONLINE_SDKWS_CONFIG_FILE} no such file." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        exit 0
    fi
    
    # bluewhale-site.properties配置文件
    printMessageLog INFO "backup file: ${ONLINE_BLUEWHALE_CONFIG_FILE}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    if [ -f ${ONLINE_BLUEWHALE_CONFIG_FILE} ]; then
        rsync -a -r ${ONLINE_BLUEWHALE_CONFIG_FILE} ${BLUEWHALE_CONFIG_FILE_BACKUP_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    else 
        printMessageLog ERROR "${ONLINE_BLUEWHALE_CONFIG_FILE} no such file." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        exit 0
    fi
    
    # 压缩部署目录
    cd ${ONLIE_DEPLOY_PATH}/../
    tar -czvf ${SDK_WS_NAME}_${ONLINE_VERSION_NUMBER}.tar.gz ${ONLIE_DEPLOY_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "execute: tar -czvf ${SDK_WS_NAME}_${ONLINE_VERSION_NUMBER}.tar.gz ${ONLIE_DEPLOY_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        printMessageLog INFO "execute: tar -czvf ${SDK_WS_NAME}_${ONLINE_VERSION_NUMBER}.tar.gz ${ONLIE_DEPLOY_PATH} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
    
    # 将压缩包复制到备份目录
    mv ${ONLIE_DEPLOY_PATH}/../${SDK_WS_NAME}_${ONLINE_VERSION_NUMBER}.tar.gz ${BACKUP_SDKWS_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "execute: mv ${ONLIE_DEPLOY_PATH}/../${SDK_WS_NAME}_${ONLINE_VERSION_NUMBER}.tar.gz ${BACKUP_SDKWS_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        printMessageLog INFO "execute: mv ${ONLIE_DEPLOY_PATH}/../${SDK_WS_NAME}_${ONLINE_VERSION_NUMBER}.tar.gz ${BACKUP_SDKWS_PATH} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
    
    cd ${CURRENT_PATH}
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        readParams
# createTime  :        2018-08-23
# description :        组件升级参数读取
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function readParams()
{
    printMessageLog INFO "readParams ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 读取升级参数
    readUpgradeParams ${SDK_WS_NAME} ${ONLINE_SDKWS_CONFIG_FILE}
    
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
    printMessageLog INFO "paramsCheck ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 公共参数校验
    if [ -z ${ES_HOST} ]; then
        printMessageLog ERROR "the parameter [ES_HOST] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${ES_PORT} ]; then
        printMessageLog ERROR "the parameter [ES_PORT] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        ES_PORT="9300"
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
        printMessageLog ERROR "the parameter [NN_REDIS_PORT] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
        printMessageLog ERROR "the parameter [GRAPHX_URL] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${PRESTO_URL} ]; then
        printMessageLog ERROR "the parameter [PRESTO_URL] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        local ret=$(isStartWith ${PRESTO_URL} "jdbc:presto")
        if [ ${ret} -ne 0 ]; then
            PRESTO_URL="jdbc:presto://"${PRESTO_URL}"/hive/default"
        fi
    fi

    if [ -z ${PRESTO_USER} ]; then
        printMessageLog ERROR "the parameter [PRESTO_USER] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${PRESTO_PASSWD} ]; then
        printMessageLog WARN "the parameter [PRESTO_PASSWD] is null, will use default value [admin]." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
    
    if [ -z ${DEFAULT_PLATFORM_ID} ]; then
        printMessageLog WARN "the parameter [DEFAULT_PLATFORM_ID] is null, use default value [default]." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        DEFAULT_PLATFORM_ID="default"
    fi

    return 0
}


# ----------------------------------------------------------------------
# FunctionName:        stop
# createTime  :        2018-08-23
# description :        组件进程停止
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function stop()
{
    printMessageLog INFO "stop ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/stop.sh

    if [ $? -ne 0 ]; then
        printMessageLog ERROR "stop ${SDK_WS_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog INFO "stop ${SDK_WS_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog INFO "uninstall ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/uninstall.sh

    if [ $? -ne 0 ]; then
        printMessageLog ERROR "uninstall ${SDK_WS_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog INFO "uninstall ${SDK_WS_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog INFO "install ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/install.sh "upgrade" "${SDK_WS_NAME}"

    if [ $? -ne 0 ]; then
        printMessageLog ERROR "install ${SDK_WS_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog INFO "install ${SDK_WS_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog INFO "start ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/start.sh

    if [ $? -ne 0 ]; then
        printMessageLog ERROR "start ${SDK_WS_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog INFO "start ${SDK_WS_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog INFO "postCheck ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 校验接口服务进程是否存在
    local status=$(jps | grep QueryProxyWebServer)
    if [ -z ${status} ]; then
        printMessageLog ERROR "QueryProxyWebServer haven't start." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog WARN "process info is: ${status}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    rm -rf ${SDKWS_CONFIG_FILE_BACKUP_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        backupComponentPackage
# createTime  :        2018-08-23
# description :        组件升级成功后备份升级包，用于回滚
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function backupComponentPackage()
{
    printMessageLog INFO "backupComponentPackage ${SDK_WS_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    backupPackage ${SDK_WS_NAME}
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "backup package  failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog INFO "backup package successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

main $*

if [ $? -ne 0 ]; then
    printMessageLog ERROR "${SDK_WS_NAME} upgrade failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    exit 1
else
    printMessageLog INFO "${SDK_WS_NAME} upgrade successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    exit 0
fi
