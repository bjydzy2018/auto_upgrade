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
    #uninstall
    #[ $? -ne 0 ] && return 1

    # 安装，配置文件修改
    install ${type}
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
# FunctionName:        paramsCheck
# createTime  :        2018-08-23
# description :        组件部署参数校验
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function paramsCheck()
{
    local action=$1
    
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
    
    if [ -z ${NL_CMS_SP_ID} ]; then
        printMessageLog ERROR "the parameter [NL_CMS_SP_ID] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${NL_CMS_PLATFORM_ID} ]; then
        printMessageLog ERROR "the parameter [NL_CMS_PLATFORM_ID] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    else
        printMessageLog WARN "FTP路径配置的值为[ ${HADOOP_FTP_DIRECTORY} ]，该路径为相对路径，不是FTP服务器的绝对路径，请确认是否正确." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        readInput
        [ $? -ne 0 ] && return 1
    fi

    if [ -z ${NN_REDIS_HOST} ]; then
        printMessageLog ERROR "the parameter [NN_REDIS_HOST] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        printMessageLog WARN "Redis服务器地址配置的值为[ ${NN_REDIS_HOST} ]，请确认是否正确." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        readInput
        [ $? -ne 0 ] && return 1
    fi

    if [ -z ${NN_REDIS_PORT} ]; then
        printMessageLog WARN "the parameter [NN_REDIS_PORT] is null, will use default value [6379]." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        NN_REDIS_PORT="6379"
    fi

    if [ -z ${KAFKA_HOST} ]; then
        printMessageLog ERROR "the parameter [KAFKA_HOST] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    # 只有部署时才校验KAFKA_HOSTNAMES参数
    if [ x"${action}" == x"deploy" ]; then
        if [ -z ${KAFKA_HOSTNAMES} ]; then
            printMessageLog ERROR "the parameter [KAFKA_HOSTNAMES] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
    fi
    
    if [ -z ${NL_SP_ID} ]; then
        printMessageLog ERROR "the parameter [NL_SP_ID] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${HIVE_PLATFORM_ID} ]; then
        printMessageLog ERROR "the parameter [HIVE_PLATFORM_ID] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    
    if [ -z ${MAP_NAME} ]; then
        printMessageLog ERROR "the parameter [MAP_NAME] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${MAP_CODE} ]; then
        printMessageLog ERROR "the parameter [MAP_CODE] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ -z ${IF_IP_2_LATITUDE} ]; then
        printMessageLog ERROR "the parameter [IF_IP_2_LATITUDE] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        if [ x"xjcbc" == x"${HIVE_PLATFORM_ID}" -a "true" != "${IF_IP_2_LATITUDE}" ]; then
            printMessageLog WARN "[IF_IP_2_LATITUDE]的值为${IF_IP_2_LATITUDE}，新疆CBC要求的是true，请确认." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            readInput
            [ $? -ne 0 ] && return 1
        elif [ x"xjcbc" != x"${HIVE_PLATFORM_ID}" -a "true" == "${IF_IP_2_LATITUDE}" ]; then
            printMessageLog WARN "[IF_IP_2_LATITUDE]的值为${IF_IP_2_LATITUDE}，请确认是否需要开启IP转地区码开关，当前已知只有新疆CBC需要开启." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            readInput
            [ $? -ne 0 ] && return 1
        fi
    fi
    
    if [ -z ${AREA_CODE_CHANGE_RULE} ]; then
        printMessageLog ERROR "the parameter [AREA_CODE_CHANGE_RULE] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        if [ x"nmggd" == x"${HIVE_PLATFORM_ID}" -a "1" != "${AREA_CODE_CHANGE_RULE}" ]; then
            printMessageLog WARN "[AREA_CODE_CHANGE_RULE]的值为${AREA_CODE_CHANGE_RULE}，内蒙古要求的是1，请确认." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            readInput
            [ $? -ne 0 ] && return 1
        elif [ x"gzgd" == x"${HIVE_PLATFORM_ID}" -a "1" != "${AREA_CODE_CHANGE_RULE}" ]; then
            printMessageLog WARN "[AREA_CODE_CHANGE_RULE]的值为${AREA_CODE_CHANGE_RULE}，贵州广电要求的是1，请确认." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            readInput
            [ $? -ne 0 ] && return 1
        elif [ x"xjcbc" == x"${HIVE_PLATFORM_ID}" -a "2" != "${AREA_CODE_CHANGE_RULE}" ]; then
            printMessageLog WARN "[AREA_CODE_CHANGE_RULE]的值为${AREA_CODE_CHANGE_RULE}，新疆CBC要求的是2，请确认." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            readInput
            [ $? -ne 0 ] && return 1
        fi
    fi
    
    if [ -z ${IS_SPLICE_SP_ID} ]; then
        printMessageLog ERROR "the parameter [IS_SPLICE_SP_ID] is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        if [ x"nmggd" == x"${HIVE_PLATFORM_ID}" -a "true" != "${IS_SPLICE_SP_ID}" ]; then
            printMessageLog WARN "[IS_SPLICE_SP_ID]的值为${IS_SPLICE_SP_ID}，内蒙古要求的是true，请确认." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            readInput
            [ $? -ne 0 ] && return 1
        elif [ x"nmggd" != x"${HIVE_PLATFORM_ID}" -a "true" == "${IS_SPLICE_SP_ID}" ]; then
            printMessageLog WARN "[IS_SPLICE_SP_ID]的值为${IS_SPLICE_SP_ID}，请确认是否需要开启在错误码前补SP_ID，当前已知只有内蒙古广电需要开启." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            readInput
            [ $? -ne 0 ] && return 1
        fi
    fi

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
    printMessageLog INFO "preCheck ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
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
    isExistMySQL ${NL_DB_HOST} ${NL_DB_USER} ${NL_DB_PASS}
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
    if [ ! -d ${BACKUP_ROOT_PATH}/${REPORTER_SYSTEM_NAME} ]; then
        printMessageLog WARN "deploy directory [${BACKUP_ROOT_PATH}/${REPORTER_SYSTEM_NAME}] is not existed, create it." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        mkdir -p ${BACKUP_ROOT_PATH}/${REPORTER_SYSTEM_NAME}/config >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        mkdir -p ${BACKUP_ROOT_PATH}/${REPORTER_SYSTEM_NAME}/crontab >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        mkdir -p ${BACKUP_ROOT_PATH}/${REPORTER_SYSTEM_NAME}/hosts >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        chmod -R 755 ${BACKUP_ROOT_PATH}/${REPORTER_SYSTEM_NAME}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    fi
    
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
    printMessageLog INFO "defaultParams ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    cat ${DEFAULT_DEPLOY_FILE_PATH} > ${DEPLOY_FILE_PATH}
    readParams
    
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
    
    # 读取部署参数
    readDeployParams
    
    # 读取crontab list
    #CRONTAB_LIST=$(readSectionList ${DEPLOY_FILE_PATH} ${CRONTAB_SECTION})
    
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
    sh ${CURRENT_PATH}/install.sh "deploy"
    
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
    printMessageLog INFO "start ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog ERROR "${REPORTER_SYSTEM_NAME} deploy failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    exit 1
else
    printMessageLog INFO "${REPORTER_SYSTEM_NAME} deploy successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    exit 0
fi
