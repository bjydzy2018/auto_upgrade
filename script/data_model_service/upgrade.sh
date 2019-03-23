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
# 组件老部署目录
readonly OLD_DEPLOY_PATH=${WWW_PATH}/bigdata

# 备份配置文件路径
readonly BACKUP_SQL_PATH=${BACKUP_ROOT_PATH}/${DATA_MODEL_SERVICE_NAME}/sql
readonly BACKUP_CONFIG_PATH=${BACKUP_ROOT_PATH}/${DATA_MODEL_SERVICE_NAME}/config
readonly BACKUP_CONFIG_FILE_PATH=${BACKUP_CONFIG_PATH}/param.ini

# ----------------------------------------------------------------------
# FunctionName:        main
# createTime  :        2018-08-23
# description :        组件部署函数入口
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    # 部署参数校验
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
# description :        组件升级前依赖校验
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function preCheck()
{
    printMessageLog INFO "preCheck ${DATA_MODEL_SERVICE_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 常用linux命令检查
    isDos2unix
    isUnzip
    
    # 报表平台节点才校验，其他节点不校验
    isExistNginx
    if [ $? -ne 0 ]; then
        printMessageLog WARN "There is no ${DATA_MODEL_SERVICE_NAME} on this node." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 0
    fi

    # 可视化平台是否安装
    isExistReportSysytem
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # 备份路径校验
    if [ ! -d ${BACKUP_ROOT_PATH}/${DATA_MODEL_SERVICE_NAME} ]; then
        printMessageLog WARN "deploy directory [${BACKUP_ROOT_PATH}/${DATA_MODEL_SERVICE_NAME}] is not existed, create it." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        mkdir -p ${BACKUP_SQL_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        mkdir -p ${BACKUP_CONFIG_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        chmod -R 755 ${BACKUP_ROOT_PATH}/${DATA_MODEL_SERVICE_NAME}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    fi
    
    printMessageLog INFO "preCheck ${DATA_MODEL_SERVICE_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        backupConfig
# createTime  :        2018-08-23
# description :        升级前备份数据库，只备份
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function backupConfig()
{
    printMessageLog INFO "backupConfig ${DATA_MODEL_SERVICE_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 部署参数文件备份
    if [ ! -d ${BACKUP_CONFIG_PATH} ]; then
        mkdir -p ${BACKUP_CONFIG_PATH}
        chmod -R 755 ${BACKUP_CONFIG_PATH} 
    fi
    rsync -a -r ${DEPLOY_PATH}/param.ini ${BACKUP_CONFIG_FILE_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # Hive集群备份hive表结构
    isExistHive ${HIVE_PLATFORM_ID}
    if [ $? -eq 0 ]; then
        local txtFile=${BACKUP_SQL_PATH}/hive_${HIVE_PLATFORM_ID}_$(getToday).txt
        local sqlFile=${BACKUP_SQL_PATH}/hive_${HIVE_PLATFORM_ID}_$(getToday).sql
        local hqlFile=${BACKUP_SQL_PATH}/hive_${HIVE_PLATFORM_ID}_$(getToday).hql
        
        hive -e 'use ${HIVE_PLATFORM_ID}; show tables;' > ${txtFile}
        awk '{print "show create table '${HIVE_PLATFORM_ID}'."$1";"}' ${txtFile} > ${sqlFile}
        hive -f "${sqlFile}" > ${hqlFile}
        
        rm -rf ${txtFile}
        rm -rf ${sqlFile}
    fi
    
    printMessageLog INFO "backupConfig ${DATA_MODEL_SERVICE_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    
    # 读取升级参数
    readUpgradeParams ${DATA_MODEL_SERVICE_NAME} ${BACKUP_CONFIG_FILE_PATH}
    
    printMessageLog INFO "readParams ${DATA_MODEL_SERVICE_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog INFO "paramsCheck ${DATA_MODEL_SERVICE_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
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
    
    if [ -z ${HIVE_PLATFORM_ID} ]; then
        printMessageLog ERROR "the parameter [HIVE_PLATFORM_ID] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog INFO "paramsCheck ${DATA_MODEL_SERVICE_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
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
    
    sh ${CURRENT_PATH}/install.sh "upgrade" ${DATA_MODEL_SERVICE_NAME}

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
    printMessageLog INFO "postCheck ${DATA_MODEL_SERVICE_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    rm -rf ${BACKUP_CONFIG_FILE_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    printMessageLog INFO "postCheck ${DATA_MODEL_SERVICE_NAME} end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog ERROR "${DATA_MODEL_SERVICE_NAME} upgrade failed." ${FUNCNAME} ${LINENO}
    exit 1
else
    printMessageLog INFO "${DATA_MODEL_SERVICE_NAME} upgrade successfully." ${FUNCNAME} ${LINENO}
    exit 0
fi
