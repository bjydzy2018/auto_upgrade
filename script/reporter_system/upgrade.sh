#!/bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)
PACKAGE_PATH=${CURRENT_PATH}/../

source ${CURRENT_PATH}/common_dep_util.sh

readonly LOG_FILE_NAME_PREFIX=`echo $(basename ${CLASS_NAME} .sh)`
LOG_FILE_NAME=${REPORTER_SYSTEM_NAME}_${LOG_FILE_NAME_PREFIX}.log
# 初始化日志
initLog ${REPORTER_SYSTEM_NAME} ${LOG_FILE_NAME}

# 组件部署目录
readonly DEPLOY_PATH=${DEPLOY_ROOT_PATH}/${MICRO_SERVICE_NAME}/${REPORTER_SYSTEM_NAME}
# 组件老部署目录
readonly OLD_DEPLOY_PATH=${WWW_PATH}/bigdata

# 线上环境版本号
ONLINE_VERSION_NUMBER=""

# 线上报表服务部署路径
ONLIE_DEPLOY_PATH=""

# 备份配置文件路径
readonly BACKUP_REPORT_PATH=${BACKUP_ROOT_PATH}/${REPORTER_SYSTEM_NAME}
readonly BACKUP_CRONTAB_PATH=${BACKUP_REPORT_PATH}/crontab
readonly BACKUP_HOSTS_PATH=${BACKUP_REPORT_PATH}/hosts
readonly BACKUP_CONFIG_PATH=${BACKUP_REPORT_PATH}/config
readonly BACKUP_NN_CONFIG_FILE_PATH=${BACKUP_CONFIG_PATH}/nn_config.php

# ----------------------------------------------------------------------
# FunctionName:        main
# createTime  :        2018-08-23
# description :        组件部署函数入口，
# TODO        :        升级前需要修改nn_config.php中的单引号和注释配置项
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    # 部署预检查
    preCheck
    [ $? -ne 0 ] && return 1
    
    # 部署参数校验
    backupConfig
    [ $? -ne 0 ] && return 1

    # 读取部署参数
    readParams
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
# description :        组件升级前依赖校验
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function preCheck()
{
    printMessageLog INFO "preCheck ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
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
    
    # Nginx安装判断
    isExistNginx
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "Nginx is not installed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # PHP安装判断
    isExistPHP
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "PHP is not installed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # MySQL安装判断
#    isExistMySQL ${NL_DB_HOST} ${NL_DB_USER} ${NL_DB_PASS}
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "MySQL connection failed, host=${NL_DB_HOST}, username=${NL_DB_USER}, passwd=${NL_DB_PASS}." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 部署路径校验
    if [ ! -d ${DEPLOY_PATH} ]; then
        printMessageLog WARN "deploy directory [${DEPLOY_PATH}] is not existed, create it." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        mkdir -p ${DEPLOY_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        chmod -R 755 ${DEPLOY_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    fi
    
    # 备份路径校验
    if [ ! -d ${BACKUP_REPORT_PATH} ]; then
        printMessageLog WARN "deploy directory [${BACKUP_REPORT_PATH}] is not existed, create it." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        mkdir -p ${BACKUP_CONFIG_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        mkdir -p ${BACKUP_CRONTAB_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        mkdir -p ${BACKUP_HOSTS_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        chmod -R 755 ${BACKUP_REPORT_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
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
    printMessageLog INFO "backupConfig ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 备份配置文件nn_config.php
    if [ -f ${DEPLOY_PATH}/nn_config.php ]; then
        ONLIE_DEPLOY_PATH=${DEPLOY_PATH}
        ONLINE_VERSION_NUMBER=$(getVersionNumber ${DEPLOY_PATH}/version)
        rsync -a -r ${DEPLOY_PATH}/nn_config.php ${BACKUP_CONFIG_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        rsync -a -r ${DEPLOY_PATH}/nn_config.ini ${BACKUP_CONFIG_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        rsync -a -r ${DEPLOY_PATH}/version.php ${BACKUP_CONFIG_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    elif [ -f ${OLD_DEPLOY_PATH}/nn_config.php ]; then
        ONLIE_DEPLOY_PATH=${OLD_DEPLOY_PATH}
        ONLINE_VERSION_NUMBER=""
        rsync -a -r ${OLD_DEPLOY_PATH}/nn_config.php ${BACKUP_CONFIG_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        rsync -a -r ${OLD_DEPLOY_PATH}/nn_config.ini ${BACKUP_CONFIG_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        rsync -a -r ${OLD_DEPLOY_PATH}/version.php ${BACKUP_CONFIG_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    fi
    
    # 备份部署目录
    cd ${ONLIE_DEPLOY_PATH}/../
    tar -czvf ${REPORTER_SYSTEM_NAME}_${ONLINE_VERSION_NUMBER}.tar.gz ${ONLIE_DEPLOY_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "execute: tar -czvf ${REPORTER_SYSTEM_NAME}_${ONLINE_VERSION_NUMBER}.tar.gz ${ONLIE_DEPLOY_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        printMessageLog INFO "execute: tar -czvf ${REPORTER_SYSTEM_NAME}_${ONLINE_VERSION_NUMBER}.tar.gz ${ONLIE_DEPLOY_PATH} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
    
    # 备份NP目录
    tar -czvf np_${ONLINE_VERSION_NUMBER}.tar.gz ${ONLIE_DEPLOY_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "execute: tar -czvf np_${ONLINE_VERSION_NUMBER}.tar.gz ${ONLIE_DEPLOY_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        printMessageLog INFO "execute: tar -czvf np_${ONLINE_VERSION_NUMBER}.tar.gz ${ONLIE_DEPLOY_PATH} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
    
    # 将压缩包复制到备份目录
    mv ${ONLIE_DEPLOY_PATH}/../${REPORTER_SYSTEM_NAME}_${ONLINE_VERSION_NUMBER}.tar.gz ${BACKUP_REPORT_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "execute: mv ${ONLIE_DEPLOY_PATH}/../${REPORTER_SYSTEM_NAME}_${ONLINE_VERSION_NUMBER}.tar.gz ${BACKUP_REPORT_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        printMessageLog INFO "execute: mv ${ONLIE_DEPLOY_PATH}/../${REPORTER_SYSTEM_NAME}_${ONLINE_VERSION_NUMBER}.tar.gz ${BACKUP_REPORT_PATH} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
    
    mv ${ONLIE_DEPLOY_PATH}/../np_${ONLINE_VERSION_NUMBER}.tar.gz ${BACKUP_REPORT_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "execute: mv ${ONLIE_DEPLOY_PATH}/../np_${ONLINE_VERSION_NUMBER}.tar.gz ${BACKUP_REPORT_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        printMessageLog INFO "execute: mv ${ONLIE_DEPLOY_PATH}/../np_${ONLINE_VERSION_NUMBER}.tar.gz ${BACKUP_REPORT_PATH} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
    
    cd ${CURRENT_PATH}
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        readParams
# createTime  :        2018-08-23
# description :        本地测试默认参数处理
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function readParams()
{
    printMessageLog INFO "readParams ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 读取升级参数
    readUpgradeParams ${REPORTER_SYSTEM_NAME} ${BACKUP_NN_CONFIG_FILE_PATH}
    
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
    printMessageLog INFO "paramsCheck ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 公共参数校验
    if [ -z ${NL_CMS_DB_HOST} ]; then
        printMessageLog ERROR "the parameter [NL_CMS_DB_HOST] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${NL_CMS_DB_USER} ]; then
        printMessageLog ERROR "the parameter [NL_CMS_DB_USER] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${NL_CMS_DB_PASS} ]; then
        printMessageLog ERROR "the parameter [NL_CMS_DB_PASS] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${NL_CMS_DB_NAME} ]; then
        printMessageLog ERROR "the parameter [NL_CMS_DB_NAME] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${NL_AAA_DB_HOST} ]; then
        printMessageLog ERROR "the parameter [NL_AAA_DB_HOST] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${NL_AAA_DB_USER} ]; then
        printMessageLog ERROR "the parameter [NL_AAA_DB_USER] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${NL_AAA_DB_PASS} ]; then
        printMessageLog ERROR "the parameter [NL_AAA_DB_PASS] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${NL_AAA_DB_NAME} ]; then
        printMessageLog ERROR "the parameter [NL_AAA_DB_NAME] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${HADOOP_FTP_HOST} ]; then
        printMessageLog ERROR "the parameter [HADOOP_FTP_HOST] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${HADOOP_FTP_USER} ]; then
        printMessageLog WARN "the parameter [HADOOP_FTP_USER] is null, will use default value [sdk]." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        HADOOP_FTP_USER="sdk"
    fi

    if [ -z ${HADOOP_FTP_PWD} ]; then
        printMessageLog WARN "the parameter [HADOOP_FTP_PWD] is null, will use default value [sdk]." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        HADOOP_FTP_PWD="sdk"
    fi

    if [ -z ${HADOOP_FTP_DIRECTORY} ]; then
        printMessageLog WARN "the parameter [HADOOP_FTP_DIRECTORY] is null, will use default value [/]." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        HADOOP_FTP_DIRECTORY="/"
    fi

    if [ -z ${NN_REDIS_HOST} ]; then
        printMessageLog ERROR "the parameter [NN_REDIS_HOST] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${NN_REDIS_PORT} ]; then
        printMessageLog WARN "the parameter [NN_REDIS_PORT] is null, will use default value [6379]." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        NN_REDIS_PORT="6379"
    fi

    if [ -z ${KAFKA_HOST} ]; then
        printMessageLog ERROR "the parameter [KAFKA_HOST] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    # 组件参数校验
    if [ -z ${NL_WEBSERVICE} ]; then
        printMessageLog ERROR "the parameter [NL_WEBSERVICE] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${NL_NEW_RECOMMEND_SERVICE_ALI} ]; then
        printMessageLog ERROR "the parameter [NL_NEW_RECOMMEND_SERVICE_ALI] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${NL_DOWNLOAD_WEBSERVICE} ]; then
        printMessageLog ERROR "the parameter [NL_DOWNLOAD_WEBSERVICE] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ -z ${SYS_LOGINID} ]; then
        printMessageLog WARN "the parameter [SYS_LOGINID] is null, will use default value [admin]." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        SYS_LOGINID="admin"
    fi

    if [ -z ${SYS_LOGINPWD} ]; then
        printMessageLog WARN "the parameter [SYS_LOGINPWD] is null, will use default value [admin]." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        SYS_LOGINPWD="admin"
    fi

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

    if [ -z ${NL_DB_NAME} ]; then
        printMessageLog ERROR "the parameter [NL_DB_NAME] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${NN_BRD_URL} ]; then
        printMessageLog ERROR "the parameter [NN_BRD_URL] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
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
    printMessageLog INFO "stop ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/stop.sh

    if [ $? -ne 0 ]; then
        printMessageLog ERROR "stop ${REPORTER_SYSTEM_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog INFO "stop ${REPORTER_SYSTEM_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog INFO "uninstall ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/uninstall.sh

    if [ $? -ne 0 ]; then
        printMessageLog ERROR "uninstall ${REPORTER_SYSTEM_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog INFO "uninstall ${REPORTER_SYSTEM_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog INFO "install ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sh ${CURRENT_PATH}/install.sh "upgrade" "${REPORTER_SYSTEM_NAME}"

    if [ $? -ne 0 ]; then
        printMessageLog ERROR "install ${REPORTER_SYSTEM_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog INFO "install ${REPORTER_SYSTEM_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    sh ${CURRENT_PATH}/start.sh

    if [ $? -ne 0 ]; then
        printMessageLog ERROR "start ${REPORTER_SYSTEM_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog INFO "start ${REPORTER_SYSTEM_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog INFO "postCheck ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 校验nginx配置是否正确
    ${NGINX_PATH}/sbin/nginx -t
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "Nginx configuration verification failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    rm -rf ${BACKUP_CONFIG_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
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
    printMessageLog INFO "backupComponentPackage ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    backupPackage ${REPORTER_SYSTEM_NAME}
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "backup package failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog INFO "backup package successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

main $*

if [ $? -ne 0 ]; then
    printMessageLog ERROR "${REPORTER_SYSTEM_NAME} upgrade failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    exit 1
else
    printMessageLog INFO "${REPORTER_SYSTEM_NAME} upgrade successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    exit 0
fi
