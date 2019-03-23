#!/bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)

source ${CURRENT_PATH}/common_dep_util.sh

readonly LOG_FILE_NAME_PREFIX=`echo $(basename ${CLASS_NAME} .sh)`
LOG_FILE_NAME=${REPORTER_SYSTEM_NAME}_${LOG_FILE_NAME_PREFIX}.log
# 初始化日志
initLog ${REPORTER_SYSTEM_NAME} ${LOG_FILE_NAME}
# 组件部署目录
readonly DEPLOY_PATH=${DEPLOY_ROOT_PATH}/${MICRO_SERVICE_NAME}/${REPORTER_SYSTEM_NAME}
# 报表平台目录
BIGDATA_PATH=${WWW_PATH}/bigdata
# 软链接目录
SOFT_LINK_PATH=${WWW_PATH}/bigdata_ky
# nn_config.php配置文件路径
readonly NN_CONFIG_FILE_PATH=${BACKUP_ROOT_PATH}/${REPORTER_SYSTEM_NAME}/config/nn_config.php

# ----------------------------------------------------------------------
# FunctionName:		main
# createTime  :		2018-08-24
# description :		组件安装程序主函数入口
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    local action=$1

    # 读取部署参数，若时本地安装，使用默认参数
    if [ x"${action}" == x"upgrade" ]; then
        local componentName=$2
        if [ -z ${componentName} ]; then
            printMessageLog ERROR "componentName is null, invlid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        fi
        # 读取升级参数
        readUpgradeParams ${componentName} ${NN_CONFIG_FILE_PATH}
        [ $? -ne 0 ] && return 1
    elif  [ x"${action}" == x"deploy" ]; then
        # 读取部署参数
        readDeployParams
        [ $? -ne 0 ] && return 1
    else
        printMessageLog ERROR "action is ${action}, invlid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 部署目录创建
    createPath
    [ $? -ne 0 ] && return 1
    
    # 文件复制
    copyFile
    [ $? -ne 0 ] && return 1
    
    # 修改权限
    setPermission
    [ $? -ne 0 ] && return 1
    
    # Nginx配置
    setSoftLinks
    [ $? -ne 0 ] && return 1
    
    # version.php文件修改
    setVersionFile
    [ $? -ne 0 ] && return 1
    
    # nn_config.php配置文件修改
    setConfigFile
    [ $? -ne 0 ] && return 1
    
    # /etc/hosts文件修改，只有首次部署需要修改，升级不做操作
    #if [ x"${action}" == x"deploy" ]; then
    #    setHosts
    #    [ $? -ne 0 ] && return 1
    #fi
    
    # crontab修改
    #setCrontab
    #updateCrontab
    #[ $? -ne 0 ] && return 1
    
    # 升级报表数据库
    #createMySQLForReportSystem ${action}
    #[ $? -ne 0 ] && return 1
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		createPath
# createTime  :		2018-08-24
# description :		组件安装目录创建
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function createPath()
{
    printMessageLog WARN "createPath() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    mkdir -p ${DEPLOY_PATH}/abtest_cms/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create path ${DEPLOY_PATH}/abtest_cms/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    mkdir -p ${DEPLOY_PATH}/api/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create path ${DEPLOY_PATH}/api/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    mkdir -p ${DEPLOY_PATH}/data/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create path ${DEPLOY_PATH}/data/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    mkdir -p ${DEPLOY_PATH}/mobile/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create path ${DEPLOY_PATH}/mobile/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    mkdir -p ${DEPLOY_PATH}/sync_plantform/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create path ${DEPLOY_PATH}/sync_plantform/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    mkdir -p ${DEPLOY_PATH}/tools/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create path ${DEPLOY_PATH}/tools/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    mkdir -p ${DEPLOY_PATH}/web/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create path ${DEPLOY_PATH}/web/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog WARN "createPath() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		copyFile
# createTime  :		2018-08-24
# description :		复制组件产品相关文件到部署目录
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function copyFile()
{
    printMessageLog WARN "copyFile() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    printMessageLog INFO "copy report system file " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    rsync -a -r ${PACKAGE_PATH}/abtest_cms/* ${DEPLOY_PATH}/abtest_cms/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${PACKAGE_PATH}/api/* ${DEPLOY_PATH}/api/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${PACKAGE_PATH}/data/* ${DEPLOY_PATH}/data/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${PACKAGE_PATH}/mobile/* ${DEPLOY_PATH}/mobile/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${PACKAGE_PATH}/sync_plantform/* ${DEPLOY_PATH}/sync_plantform/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${PACKAGE_PATH}/tools/* ${DEPLOY_PATH}/tools/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${PACKAGE_PATH}/web/* ${DEPLOY_PATH}/web/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${PACKAGE_PATH}/index.php ${DEPLOY_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${PACKAGE_PATH}/list.txt ${DEPLOY_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${PACKAGE_PATH}/nn_config.ini ${DEPLOY_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${PACKAGE_PATH}/nn_config.php ${DEPLOY_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${PACKAGE_PATH}/readme.txt ${DEPLOY_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${PACKAGE_PATH}/version.php ${DEPLOY_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${PACKAGE_PATH}/version ${DEPLOY_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    printMessageLog INFO "copy np file " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    tar -xzvf ${PACKAGE_PATH}/third/np.tar.gz -C ${DEPLOY_PATH}/../ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1 
    
    printMessageLog WARN "copyFile() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		setPermission
# createTime  :		2018-08-24
# description :		权限修改
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function setPermission()
{
    printMessageLog WARN "setPermission() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 目录属组修改为www:www
    chown -R www:www ${DEPLOY_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    chown -R www:www ${DEPLOY_PATH}/../np/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # 目录权限修改为755
    chmod -R 755 ${DEPLOY_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    chmod -R 755 ${DEPLOY_PATH}/../np/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # 执行文件权限修改为744
    chmod 744 ${DEPLOY_PATH}/*.php >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    chmod 744 ${DEPLOY_PATH}/*/*.php >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # 配置文件权限修改为644
    chmod 644 ${DEPLOY_PATH}/*.ini >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    chmod 644 ${DEPLOY_PATH}/*/*.ini >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    chmod 644 ${DEPLOY_PATH}/*.txt >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    chmod 644 ${DEPLOY_PATH}/*/*.txt >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    printMessageLog WARN "setPermission() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		setSoftLinks
# createTime  :		2018-08-24
# description :		www目录软链接配置
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function setSoftLinks()
{
    printMessageLog WARN "setSoftLinks() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    if [ -d ${SOFT_LINK_PATH} ]; then
        printMessageLog WARN "${SOFT_LINK_PATH} is existed, delete it." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        rm -rf ${SOFT_LINK_PATH}  >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    fi
    
    # 创建软链接到Nginx目录
    ln -s ${DEPLOY_PATH} ${SOFT_LINK_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then 
        printMessageLog ERROR "create soft links ${SOFT_LINK_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        printMessageLog INFO "create soft links ${SOFT_LINK_PATH} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
    
    printMessageLog WARN "setSoftLinks() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		setConfigFile
# createTime  :		2018-08-24
# description :		nn_config.php配置文件修改
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function setConfigFile()
{
    printMessageLog WARN "setConfigFile() starting ... " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # nn_config.php配置文件路径
    local nnConfigFilePath=${DEPLOY_PATH}/nn_config.php
    # version.ini配置文件路径
    local nnConfigIniFilePath=${DEPLOY_PATH}/nn_config.ini
    # version.php配置文件路径
    local versionFilePath=${DEPLOY_PATH}/version.php
    
    dos2unix ${nnConfigFilePath}
    dos2unix ${nnConfigIniFilePath}
    dos2unix ${versionFilePath}

    # 修改version.php文件修改
    printMessageLog INFO "update file: ${nnConfigFilePath}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    modifyPhpConfig ${nnConfigFilePath} "NL_CMS_DB_HOST_1" ${NL_CMS_DB_HOST}
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NL_CMS_DB_USER_1" ${NL_CMS_DB_USER} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NL_CMS_DB_PASS_1" ${NL_CMS_DB_PASS} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NL_CMS_DB_NAME_1" ${NL_CMS_DB_NAME} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NL_SP_ID_1" ${NL_CMS_SP_ID} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NL_PLATFORM_ID_1" ${NL_CMS_PLATFORM_ID} 
    [ $? -ne 0 ] && return 1
    
    modifyPhpConfig ${nnConfigFilePath} "NL_AAA_DB_HOST_1" ${NL_AAA_DB_HOST} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NL_AAA_DB_USER_1" ${NL_AAA_DB_USER} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NL_AAA_DB_PASS_1" ${NL_AAA_DB_PASS} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NL_AAA_DB_NAME_1" ${NL_AAA_DB_NAME} 
    [ $? -ne 0 ] && return 1
    
    modifyPhpConfig ${nnConfigFilePath} "HADOOP_FTP_HOST" ${HADOOP_FTP_HOST} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "HADOOP_FTP_USER" ${HADOOP_FTP_USER} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "HADOOP_FTP_PWD" ${HADOOP_FTP_PWD} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "HADOOP_FTP_DIRECTORY" ${HADOOP_FTP_DIRECTORY}
    [ $? -ne 0 ] && return 1
    
    modifyPhpConfig ${nnConfigFilePath} "NN_REDIS_HOST" ${NN_REDIS_HOST}
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NN_REDIS_PORT" ${NN_REDIS_PORT}
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NN_REDIS_PASS" ${NN_REDIS_PASS} 
    [ $? -ne 0 ] && return 1
    
    modifyPhpConfig ${nnConfigFilePath} "KAFKA_HOST" ${KAFKA_HOST} 
    [ $? -ne 0 ] && return 1
    
    modifyPhpConfig ${nnConfigFilePath} "NL_PLATFORM_ID" ${HIVE_PLATFORM_ID} 
    [ $? -ne 0 ] && return 1
    
    modifyPhpConfig ${nnConfigFilePath} "NL_WEBSERVICE" ${NL_WEBSERVICE} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NL_NEW_RECOMMEND_SERVICE_ALI" ${NL_NEW_RECOMMEND_SERVICE_ALI} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NL_DOWNLOAD_WEBSERVICE" ${NL_DOWNLOAD_WEBSERVICE} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "SYS_LOGINID" ${SYS_LOGINID} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "SYS_LOGINPWD" ${SYS_LOGINPWD} 
    [ $? -ne 0 ] && return 1
    
    modifyPhpConfig ${nnConfigFilePath} "NL_DB_HOST" ${NL_DB_HOST}
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NL_DB_USER" ${NL_DB_USER} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NL_DB_PASS" ${NL_DB_PASS} 
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NL_DB_NAME" ${NL_DB_NAME}
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${nnConfigFilePath} "NN_BRD_URL" ${NN_BRD_URL}
    [ $? -ne 0 ] && return 1
    
    # 修改version.php文件修改
    printMessageLog INFO "update file: ${versionFilePath}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    modifyPhpConfig ${versionFilePath} "MAP_NAME" ${MAP_NAME}
    [ $? -ne 0 ] && return 1
    modifyPhpConfig ${versionFilePath} "MAP_CODE" ${MAP_CODE}
    [ $? -ne 0 ] && return 1
    
    # 修改version.ini文件修改
    if [ x"true" == x"${IF_IP_2_LATITUDE}" ]; then
        printMessageLog INFO "update file: ${nnConfigIniFilePath}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        modifyConfig "is_ip_complement_region" "1" ${nnConfigIniFilePath}
        modifyConfig "is_lbs_complement_region" "1" ${nnConfigIniFilePath}
        [ $? -ne 0 ] && return 1
    fi
   
    printMessageLog WARN "setConfigFile() end. " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		setVersionFile
# createTime  :		2018-08-24
# description :		version.php文件修改
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function setVersionFile()
{
    printMessageLog WARN "setVersionFile() starting ... " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    local curVersionFilePath=${CURRENT_PATH}/version.php
    local depVersionFilePath=${DEPLOY_PATH}/version.php
    
    if [ ! -f ${curVersionFilePath} ]; then
        printMessageLog ERROR "${curVersionFilePath} no such file." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ ! -f ${depVersionFilePath} ]; then
        printMessageLog ERROR "${depVersionFilePath} no such file." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 使用配置文件全量替换部署目录下version.php文件
    cat ${curVersionFilePath} > ${depVersionFilePath}
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "replace ${depVersionFilePath} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 更新version.php文件的版本号
    cd ${DEPLOY_PATH}/
    dos2unix version.php
    
    sed -i "s#\s*PLANT_VERSION.*#PLANT_VERSION\", \"${VERSION_NUMBER}\");#g" version.php >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "update ${depVersionFilePath} version failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    cd ${CURRENT_PATH}
    
    printMessageLog WARN "setVersionFile() end. " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		setHosts
# createTime  :		2018-08-24
# description :		/etc/hosts文件修改
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function setHosts()
{
    printMessageLog WARN "KAFKA_HOSTNAMES = ${KAFKA_HOSTNAMES} " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 修改前先备份
    cat ${HOSTS_PATH} > ${CURRENT_PATH}/$(getToday)_install.hosts >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    backupFile ${CURRENT_PATH}/$(getToday)_install.hosts ${BACKUP_ROOT_PATH}/${REPORTER_SYSTEM_NAME}/hosts "hosts"

    if [ $? -eq 0 ]; then
        printMessageLog DEBUG "rm -rf ${CURRENT_PATH}/$(getToday)_install.hosts" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        rm -rf ${CURRENT_PATH}/$(getToday)_install.hosts
    else
        printMessageLog ERROR "backup /etc/hosts failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi    
    
    # 文件格式标准化
    dos2unix ${HOSTS_PATH}
 
    # 设置分隔符
    IFS=","
    # 另一种拆分方式
    # local array=${KAFKA_HOSTNAMES//,/ };
    local array=(${KAFKA_HOSTNAMES})
    for str in ${array[@]}
    do
        printMessageLog DEBUG "str = ${str}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        IFS=":"
        local arr=(${str})
        local ipAddr=${arr[0]}
        local hostName=${arr[1]}
        
        # 若当前IP已存在，先删除再添加，否则直接添加
        local isExist=$(cat ${HOSTS_PATH} | grep "${ipAddr}")
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "get ${ipAddr} from ${HOSTS_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        elif [ ! -z "${isExist}" ]; then
            printMessageLog DEBUG "delete ${ipAddr} from ${HOSTS_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            sed -i '/'${ipAddr}'/d' ${HOSTS_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        fi
        
        printMessageLog DEBUG "add [${ipAddr} ${hostName}] to ${HOSTS_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        echo "${ipAddr}    ${hostName}" >> ${HOSTS_PATH}
        
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "update ${HOSTS_PATH} add [${ipAddr}    ${hostName}] failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        else
            printMessageLog INFO "update ${HOSTS_PATH} add [${ipAddr}    ${hostName}] successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        fi
    done
    
    # 删除空行
    sed -i '/^$/d' ${HOSTS_PATH}
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		setCrontab
# createTime  :		2018-08-24
# description :		crontab修改
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function setCrontab()
{
    # 修改前备份crontab任务列表
    crontab -l > ${CURRENT_PATH}/$(getToday)_install.crontab >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    backupFile ${CURRENT_PATH}/$(getToday)_install.crontab ${BACKUP_ROOT_PATH}/${REPORTER_SYSTEM_NAME}/crontab "crontab"
    if [ $? -eq 0 ]; then
        printMessageLog DEBUG "rm -rf ${CURRENT_PATH}/$(getToday)_install.crontab" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        rm -rf ${CURRENT_PATH}/$(getToday)_install.crontab
    else
        printMessageLog ERROR "backup crontab failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 文件格式标准化
    dos2unix ${CRONTAB_PATH}
    
    # 先判断
    local isExist=""
    
    # 配置的crontab列表
    if [ -z "${CRONTAB_LIST}" -o 0=${#CRONTAB_LIST[@]} ]; then
        printMessageLog INFO "crontab list is null, no need to modify." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 0
    fi
    
    # 将结果转换为数组
    
    
    # 遍历数组，分别写入crontab文件
    for list in ${CRONTAB_LIST[@]}
    do
        # 判断定时器任务是否存在，若存在，则不添加
        isExist=$(cat ${CRONTAB_PATH} | grep "${list}")
        if [ -z "${isExist}" ]; then
            printMessageLog INFO "add crontab: ${list}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            echo "${list}" >> ${CRONTAB_PATH}
        else
            printMessageLog INFO "crontab list is null, no need to modify." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        fi
    done
    
    # 删除空行
    sed -i '/^$/d' ${CRONTAB_PATH}
    
    # 重启crontab
    service crond restart
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "service crond restart failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    else    
        printMessageLog INFO "service crond restart successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		updateCrontab
# createTime  :		2019-03-05
# description :		crontab修改
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function updateCrontab()
{
    printMessageLog WARN "updateCrontab() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 修改前备份crontab任务列表
    crontab -l > ${CURRENT_PATH}/$(getToday)_install.crontab >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    backupFile ${CURRENT_PATH}/$(getToday)_install.crontab ${BACKUP_ROOT_PATH}/${REPORTER_SYSTEM_NAME}/crontab "crontab"
    if [ $? -eq 0 ]; then
        printMessageLog DEBUG "rm -rf ${CURRENT_PATH}/$(getToday)_install.crontab" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        rm -rf ${CURRENT_PATH}/$(getToday)_install.crontab
    else
        printMessageLog ERROR "backup crontab failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 文件格式标准化
    dos2unix ${CRONTAB_PATH}
    
    printMessageLog INFO "Excute: sed -i 's/\/data\/starcor\/www\/bigdata\//\/data\/starcor\/www\/bigdata_ky\//g' ${CRONTAB_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sed -i 's/\/data\/starcor\/www\/bigdata\//\/data\/starcor\/www\/bigdata_ky\//g' ${CRONTAB_PATH}
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "update crontab failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        printMessageLog INFO "update crontab successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
    
    # 重启crontab
    service crond restart
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "service crond restart failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else    
        printMessageLog INFO "service crond restart successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
    
    printMessageLog WARN "updateCrontab() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		createMySQLForReportSystem
# createTime  :		2018-08-26
# description :		创建报表平台MySQL数据库
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function createMySQLForReportSystem()
{
    printMessageLog WARN "createMySQLForReportSystem() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    local action=$1
    local updateSQL="DELETE FROM nns_custom_visualization_ui WHERE nns_id NOT IN ( SELECT nns_id FROM ( SELECT max(nns_id) nns_id FROM nns_custom_visualization_ui GROUP BY nns_name ) a );"
    
    if [ x"${action}" = x"upgrade" ]; then
        printMessageLog DEBUG "mysql -h${NL_DB_HOST} -u${NL_DB_USER} -p${NL_DB_PASS} -D${NL_DB_NAME} -e \"${updateSQL}\"" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        mysql -h${NL_DB_HOST} -u${NL_DB_USER} -p${NL_DB_PASS} -D${NL_DB_NAME} -e "${updateSQL}" >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "update database ${NL_DB_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
        
        # 查看需要执行的SQL命令
        printMessageLog INFO "check the upgrade SQL, excute: ${SOFT_LINK_PATH}/tools/doctrine/bin/doctrine orm:schema-tool:update --dump-sql" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        ${SOFT_LINK_PATH}/tools/doctrine/bin/doctrine orm:schema-tool:update --dump-sql
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "get upgrade MySQL failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        else
            printMessageLog INFO "please check the upgrade SQL if correct ... " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            sleep 60
        fi
        
        # 执行sql更新操作
        printMessageLog INFO "upgrade MySQL table" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        ${SOFT_LINK_PATH}/tools/doctrine/bin/doctrine orm:schema-tool:update --force
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "update database ${NL_DB_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        else
            printMessageLog INFO "update database ${NL_DB_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        fi 
    else
        # 判断数据库是否存在
        isExistMySQLDatabase ${NL_DB_HOST} ${NL_DB_USER} ${NL_DB_PASS} ${NL_DB_NAME}
        if [ $? -ne 0 ]; then
            printMessageLog INFO "database ${NL_DB_NAME} is not exist, need to create it." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            
            # 创建指定数据库
            printMessageLog DEBUG "mysql -h${NL_DB_HOST} -u${NL_DB_USER} -p${NL_DB_PASS} -e \"CREATE DATABASE ${NL_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;\" " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            mysql -h${NL_DB_HOST} -u${NL_DB_USER} -p${NL_DB_PASS} -e "CREATE DATABASE ${NL_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
        
            if [ $? -ne 0 ]; then
                printMessageLog ERROR "create database ${NL_DB_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
                return 1
            fi
        else
            printMessageLog INFO "database ${NL_DB_NAME} is existed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        fi
        
        # 查看需要执行的SQL命令
        printMessageLog INFO "check the SQL, excute: ${SOFT_LINK_PATH}/tools/doctrine/bin/doctrine orm:schema-tool:create --dump-sql" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        ${SOFT_LINK_PATH}/tools/doctrine/bin/doctrine orm:schema-tool:create --dump-sql
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "get upgrade MySQL failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        else
            printMessageLog INFO "please check the SQL if correct ... " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            sleep 60
        fi
        
        # 执行sql更新操作
        printMessageLog INFO "create MySQL table" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        ${SOFT_LINK_PATH}/tools/doctrine/bin/doctrine orm:schema-tool:update --force
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "create database ${NL_DB_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        else
            printMessageLog INFO "update database ${NL_DB_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        fi    
    fi

    printMessageLog WARN "createMySQLForReportSystem() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

main $*
