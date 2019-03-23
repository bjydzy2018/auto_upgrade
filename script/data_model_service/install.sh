#!/bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)

source ${CURRENT_PATH}/common_dep_util.sh

readonly LOG_FILE_NAME_PREFIX=`echo $(basename ${CLASS_NAME} .sh)`
LOG_FILE_NAME=${DATA_MODEL_SERVICE_NAME}_${LOG_FILE_NAME_PREFIX}.log
# 初始化日志
initLog ${DATA_MODEL_SERVICE_NAME} ${LOG_FILE_NAME}

# 组件部署目录
readonly DEPLOY_PATH=${DEPLOY_ROOT_PATH}/${MICRO_SERVICE_NAME}/${DATA_MODEL_SERVICE_NAME}
# 报表平台MySQL数据库名称
readonly REPORT_MYSQL_DBNAME="nn_bigdata_test"

# 任务文件目录
TASK_DIRECTORY_PATH=${CURRENT_PATH}/../task

# sql文件
SQL_FILE_PATH=${TASK_DIRECTORY_PATH}/sql
# cube文件目录
CUBE_FILE_PATH=${TASK_DIRECTORY_PATH}/cube
# 调度任务文件目录
SCHEDULE_FILE_PATH=${TASK_DIRECTORY_PATH}/schedule

# 备份配置文件路径
readonly BACKUP_SQL_PATH=${BACKUP_ROOT_PATH}/${DATA_MODEL_SERVICE_NAME}/sql
readonly BACKUP_CONFIG_PATH=${BACKUP_ROOT_PATH}/${DATA_MODEL_SERVICE_NAME}/config
readonly BACKUP_CONFIG_FILE_PATH=${BACKUP_CONFIG_PATH}/param.ini

ACTION_TYPE=""

# ----------------------------------------------------------------------
# FunctionName:		main
# createTime  :		2018-08-24
# description :		组件安装程序主函数入口
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    ACTION_TYPE=$1

    # 读取部署参数，若时本地安装，使用默认参数
    if [ x"${ACTION_TYPE}" == x"upgrade" ]; then
        local componentName=$2
        if [ -z ${componentName} ]; then
            printMessageLog ERROR "componentName is null, invlid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        fi
        # 读取升级参数
        printMessageLog DEBUG "componentName=${componentName}, configFilePath=${BACKUP_CONFIG_FILE_PATH}." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        readUpgradeParams ${componentName} ${BACKUP_CONFIG_FILE_PATH}
        [ $? -ne 0 ] && return 1
    elif  [ x"${ACTION_TYPE}" == x"deploy" ]; then
        # 读取部署参数
        readDeployParams
        [ $? -ne 0 ] && return 1
    else
        printMessageLog ERROR "action is ${ACTION_TYPE}, invlid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 复制文件到部署目录
    copyFile
    [ $? -ne 0 ] && return 1
    
    # 该节点是Hive集群节点，兼容报表平台和Hive共存
    isExistHive
    if [ $? -eq 0 ]; then
        # 创建/升级集群MySQL数据库
        createMySQLForCLuster
        [ $? -ne 0 ] && return 1
        
        # 创建蓝鲸平台Hive数据库
        createHiveDatabase
        [ $? -ne 0 ] && return 1
        
        # 导入调度任务
        importScheduleTask
        [ $? -ne 0 ] && return 1
    fi
    
    # 该节点是Kylin节点
    isExistKylin
    if [ $? -eq 0 ]; then
        # 导入Kylin元数据信息
        importKylinMetaData
        [ $? -ne 0 ] && return 1
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		copyFile
# createTime  :		2018-08-26
# description :		复制版本文件和部署参数文件到部署目录
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function copyFile()
{
    printMessageLog WARN "copyFile() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    local paramFile=${PACKAGE_PATH}/script/param.ini
    if [ x"${ACTION_TYPE}" = x"upgrade" ]; then
        paramFile=${BACKUP_ROOT_PATH}/${DATA_MODEL_SERVICE_NAME}/config/param.ini
    fi
    
    # 复制配置文件
    if [ ! -d ${DEPLOY_PATH} ]; then
        mkdir -p ${DEPLOY_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "create path ${DEPLOY_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
    fi
    rsync -a -r ${paramFile} ${DEPLOY_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # 复制创建视图工具
    if [ -d ${DEPLOY_PATH}/schedule ]; then
        mkdir -p ${DEPLOY_PATH}/schedule >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "create path ${DEPLOY_PATH}/schedule failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
    fi
    rsync -a -r ${PACKAGE_PATH}/tools/hive_create_view.sh ${DEPLOY_PATH}/schedule >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    printMessageLog WARN "copyFile() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}



# ----------------------------------------------------------------------
# FunctionName:		createMySQLForCLuster
# createTime  :		2018-08-26
# description :		创建/升级集群MySQL数据库
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function createMySQLForCLuster()
{
    printMessageLog INFO "createMySQLForCLuster starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 若是升级操作，需要执行增量SQL
    if [ x"${ACTION_TYPE}" = x"upgrade" ]; then
        MYSQL_FILE_PATH=${CURRENT_PATH}/../task/${VERSION_NUMBER}_mysql_upgrade.sql
    fi

    sed -i "1,2s/platformid/${CLUSTER_MYQL_DB_DBNAME}/g" ${MYSQL_FILE_PATH}
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "update file ${MYSQL_FILE_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 判断数据库是否存在
    mysql -h${CLUSTER_MYQL_DB_HOST} -u${CLUSTER_MYQL_DB_USER} -p${CLUSTER_MYQL_DB_PASSWD} -e "use ${CLUSTER_MYQL_DB_DBNAME};" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog INFO "database ${CLUSTER_MYQL_DB_DBNAME} is not existed, create it." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        printMessageLog INFO "mysql -h${CLUSTER_MYQL_DB_HOST} -u${CLUSTER_MYQL_DB_USER} -p${CLUSTER_MYQL_DB_PASSWD} -e \"CREATE DATABASE ${CLUSTER_MYQL_DB_DBNAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;\" " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        
        # 创建数据库
        mysql -h${CLUSTER_MYQL_DB_HOST} -u${CLUSTER_MYQL_DB_USER} -p${CLUSTER_MYQL_DB_PASSWD} -e "CREATE DATABASE ${CLUSTER_MYQL_DB_DBNAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;" >/dev/null 2>&1
        
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "create database ${CLUSTER_MYQL_DB_DBNAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        else
            printMessageLog INFO "create database ${CLUSTER_MYQL_DB_DBNAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        fi
    else
        printMessageLog INFO "database ${CLUSTER_MYQL_DB_DBNAME} is existed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
    
    # 执行SQL语句
    printMessageLog INFO "mysql -h${CLUSTER_MYQL_DB_HOST} -u${CLUSTER_MYQL_DB_USER} -p${CLUSTER_MYQL_DB_PASSWD} -D${CLUSTER_MYQL_DB_DBNAME} < ${MYSQL_FILE_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    mysql -h${CLUSTER_MYQL_DB_HOST} -u${CLUSTER_MYQL_DB_USER} -p${CLUSTER_MYQL_DB_PASSWD} -D${CLUSTER_MYQL_DB_DBNAME} < ${MYSQL_FILE_PATH}
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "update mysql failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        printMessageLog ERROR "update mysql successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
    
    printMessageLog ERROR "createMySQLForCLuster successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		createHiveDatabase
# createTime  :		2018-08-26
# description :		创建Hive数据库
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function createHiveDatabase()
{
    printMessageLog WARN "createHiveDatabase() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 若是升级操作，执行增量SQL
    if [ x"${ACTION_TYPE}" = x"upgrade" ]; then
        HIVE_FILE_PATH=${CURRENT_PATH}/../task/${VERSION_NUMBER}_hive_upgrade.sql
    fi
    
    sed -i "1,2s/platformid/${HIVE_PLATFORM_ID}/g" ${HIVE_FILE_PATH}
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "update file ${HIVE_FILE_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 判断数据库是否存在
    isExistHive ${HIVE_PLATFORM_id}
    
    # 执行SQL语句
    printMessageLog INFO "hive -f \"${HIVE_FILE_PATH}\"" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    hive -f "${HIVE_FILE_PATH}" >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "update hive failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog WARN "createHiveDatabase() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		importScheduleTask
# createTime  :		2018-08-26
# description :		调度任务导入 @TODO
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function importScheduleTask()
{
    # 因蓝鲸平台未提供导入接口，暂不实现
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		updateScheduleParams
# createTime  :		2019-03-18
# description :		修改蓝鲸平台中的自定义变量 @TODO
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function updateScheduleParams()
{
    # 因蓝鲸平台未提供导入接口，暂不实现
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		importScheduleTask
# createTime  :		2019-02-01
# description :		调度任务导入
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function importKylinMetaData()
{
    # kylin元数据需要支持跨版本升级，依次递增执行，每个版本只包含当前版本的cube信息
    # 部署时，依次执行当前版本及以下所有cube导入
    # 升级时，依次执行当前版本及现网所在版本间所有cube导入
    if [ x"${ACTION_TYPE}" == x"upgrade" ]; then
        local componentName=$2
        if [ -z ${componentName} ]; then
            printMessageLog ERROR "componentName is null, invlid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        fi
        # 读取版本号
        printMessageLog DEBUG "componentName=${componentName}, configFilePath=${BACKUP_CONFIG_FILE_PATH}." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        readUpgradeParams ${componentName} ${BACKUP_CONFIG_FILE_PATH}
        [ $? -ne 0 ] && return 1
    elif  [ x"${ACTION_TYPE}" == x"deploy" ]; then
        printMessageLog INFO "upgrade all cube metadata." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        # 获取zip文件列表
        ZIP_FILE_LIST=$(ls ${SCHEDULE_FILE_PATH}/ | grep -E "backup_([0-9]).([0-9]{2}).zip" | sort -k1.5n)
        [ $? -ne 0 ] && return 1
    else
        printMessageLog ERROR "action is ${ACTION_TYPE}, invlid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 需要检测当前cube是否存在低版本的cube信息存在，避免导入时将已存在的cube存储数据清空
    # 暂不实现
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		createView
# createTime  :		2019-03-18
# description :		创建视图，包括default库和allplatform库 @TODO
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function createView()
{

}

# ----------------------------------------------------------------------
# FunctionName:		deployTools
# createTime  :		2019-03-18
# description :		自定义工具部署，包括创建视图、任务开始节点等 @TODO
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function deployTools()
{

}

main $*
