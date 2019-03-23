#!/bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)

source ${CURRENT_PATH}/common_dep_util.sh

readonly LOG_FILE_NAME_PREFIX=`echo $(basename ${CLASS_NAME} .sh)`
LOG_FILE_NAME=${SDK_WS_NAME}_${LOG_FILE_NAME_PREFIX}.log
# 初始化日志
initLog ${SDK_WS_NAME} ${LOG_FILE_NAME}
# 组件部署目录
readonly DEPLOY_PATH=${DEPLOY_ROOT_PATH}/${MICRO_SERVICE_NAME}/${SDK_WS_NAME}
readonly DEPLOY_APPS_PATH=${DEPLOY_PATH}/apps_repo
readonly DEPLOY_VERSION_PATH=${DEPLOY_APPS_PATH}/${VERSION_NUMBER}_${VERSION_NUMBER}
readonly DEPLOY_APPS_CORE_PATH=${DEPLOY_VERSION_PATH}/core
readonly DEPLOY_APPS_PLUGINS_PATH=${DEPLOY_VERSION_PATH}/plugins
readonly DEPLOY_APPS_CONF_PATH=${DEPLOY_VERSION_PATH}/conf
readonly DEPLOY_APPS_DATA_PATH=${DEPLOY_VERSION_PATH}/data

# sdkws.properties配置文件路径
readonly SDKWS_CONFIG_FILE_PATH=${DEPLOY_APPS_CONF_PATH}/sdkws.properties
# bluewhale-site.properties配置文件路径
readonly BLUEWHALE_SITE_CONFIG_FILE_PATH=${DEPLOY_PATH}/conf/bluewhale-site.properties
# 备份配置文件路径
readonly BACKUP_CONFIG_PATH=${BACKUP_ROOT_PATH}/${SDK_WS_NAME}/config
readonly BACKUP_CONFIG_FILE_PATH=${BACKUP_CONFIG_PATH}/sdkws.properties

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
        printMessageLog DEBUG "componentName=${componentName}, configFilePath=${BACKUP_CONFIG_FILE_PATH}." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        readUpgradeParams ${componentName} ${BACKUP_CONFIG_FILE_PATH}
        [ $? -ne 0 ] && return 1
    elif  [ x"${action}" == x"deploy" ]; then
        # 读取部署参数
        readDeployParams
        [ $? -ne 0 ] && return 1
    else
        printMessageLog ERROR "action is [${action}], invlid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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

    # 配置文件修改
    setConfigFile
    [ $? -ne 0 ] && return 1
    
    # 配置软链接
    setSoftLink
    [ $? -ne 0 ] && return 1
    
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
    
    if [ ! -d ${BACKUP_CONFIG_PATH}/ ]; then
        printMessageLog INFO "create path: ${BACKUP_CONFIG_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        mkdir -p ${BACKUP_CONFIG_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "create path ${BACKUP_CONFIG_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
    fi
    
    printMessageLog INFO "check path: ${DEPLOY_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    if [ -d ${DEPLOY_PATH} ]; then
        printMessageLog INFO "delete path: ${DEPLOY_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        rm -rf ${DEPLOY_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    fi
    
    printMessageLog INFO "create path: ${DEPLOY_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    mkdir -p ${DEPLOY_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create path ${DEPLOY_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog INFO "create path: ${DEPLOY_APPS_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    mkdir -p ${DEPLOY_APPS_PATH}
    [[ $? -ne 0 ]] && printMessageLog ERROR "create path: ${DEPLOY_APPS_PATH} failed" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    printMessageLog INFO "create path: ${DEPLOY_VERSION_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    mkdir -p ${DEPLOY_VERSION_PATH}
    [[ $? -ne 0 ]] && printMessageLog ERROR "create path: ${DEPLOY_VERSION_PATH} failed" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    printMessageLog INFO "create path: ${DEPLOY_APPS_CORE_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    mkdir -p ${DEPLOY_APPS_CORE_PATH}
    [[ $? -ne 0 ]] && printMessageLog ERROR "create path: ${DEPLOY_APPS_CORE_PATH} failed" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    printMessageLog INFO "create path: ${DEPLOY_APPS_CONF_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    mkdir -p ${DEPLOY_APPS_CONF_PATH}
    [[ $? -ne 0 ]] && printMessageLog ERROR "create path: ${DEPLOY_APPS_CONF_PATH} failed" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    printMessageLog INFO "create path: ${DEPLOY_APPS_DATA_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    mkdir -p ${DEPLOY_APPS_DATA_PATH}
    [[ $? -ne 0 ]] && printMessageLog ERROR "create path: ${DEPLOY_APPS_DATA_PATH} failed" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    printMessageLog INFO "create path: ${DEPLOY_APPS_PLUGINS_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    mkdir -p ${DEPLOY_APPS_PLUGINS_PATH}
    [[ $? -ne 0 ]] && printMessageLog ERROR "create path: ${DEPLOY_APPS_PLUGINS_PATH} failed" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    chmod -R 755 ${DEPLOY_PATH}
    chmod -R 755 ${BACKUP_CONFIG_PATH}
    
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
    local versionNum="${VERSION_NUMBER:1}"
    printMessageLog WARN "copyFile starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 接口服务程序外壳解压
    printMessageLog INFO "start decompressing file, tar -xzvf ${PACKAGE_PATH}/third/sdk_ws.tar.gz" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    tar -xzvf ${PACKAGE_PATH}/third/sdk_ws.tar.gz -C ${DEPLOY_PATH}/../
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "excute tar -xzvf ${PACKAGE_PATH}/third/sdk_ws.tar.gz -C ${DEPLOY_PATH}/../ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 删除压缩包
    rm -rf ${DEPLOY_PATH}/../sdk_ws.tar.gz
      
    # 删除单版本号目录
    rm -rf ${DEPLOY_APPS_PATH}/${VERSION_NUMBER}
    
    # 清空多余版本的模块，保留最新的版本
    cd ${DEPLOY_APPS_PATH}/
#    ls -l -r ${DEPLOY_APPS_PATH}/ | grep "v" | awk '/^d/ {if(NR>1){print $NF}}' | xargs rm -rf
    
    # 将模块版本号命名成发布版本号
    printMessageLog INFO "standardized version directory." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    local versions=$(ls -l -r ${DEPLOY_APPS_PATH}/ | grep "v" | awk '/^d/ {print $NF}')
    for version in ${versions[@]}
    do
        if [ x"${version}" == x"${VERSION_NUMBER}_${VERSION_NUMBER}" ]; then
            continue
        else
            mv -f ${version} ${VERSION_NUMBER}_${VERSION_NUMBER}
            if [ $? -ne 0 ]; then
                printMessageLog ERROR "mv -f ${version} ${VERSION_NUMBER}_${VERSION_NUMBER} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
                return 1
            fi
        fi
        
        
    done
    
    cd ${CURRENT_PATH}
    
    # 配置文件复制，一定要先执行上一步，修改版本号
    printMessageLog INFO "copy configuration files." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    rsync -a -r ${PACKAGE_PATH}/conf/sdkws.properties ${DEPLOY_APPS_CONF_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    [[ $? -ne 0 ]] && return 1
    rsync -a -r ${PACKAGE_PATH}/conf/bluewhale-site.properties ${DEPLOY_PATH}/conf/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    [[ $? -ne 0 ]] && return 1
    rsync -a -r ${PACKAGE_PATH}/conf/*.json ${DEPLOY_APPS_CONF_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    [[ $? -ne 0 ]] && return 1
    rsync -a -r ${PACKAGE_PATH}/conf/*.xml ${DEPLOY_APPS_CONF_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    [[ $? -ne 0 ]] && return 1
    rsync -a -r ${PACKAGE_PATH}/conf/indexValidation ${DEPLOY_APPS_CONF_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    [[ $? -ne 0 ]] && return 1
    
    # 复制接口模块jar包
    printMessageLog INFO "copy module plugins." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    local modules=$(ls -l ${PACKAGE_PATH}/module/ | grep "zip" | awk '{print $NF}')
    for module in ${modules[@]}
    do
        isEndWith ${module} "-${versionNum}.zip"
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "${module} file is invalid, must end with [-${versionNum}.zip]." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            continue
        else
            local moduleName=$(echo "${module}" | sed 's/-'${versionNum}'.zip//g')
            if [ -z "${moduleName}" ]; then
                printMessageLog ERROR "get module name failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
                continue
            else
                # 解压文件
                printMessageLog INFO "zip module file: unzip -o -d ${DEPLOY_APPS_PLUGINS_PATH}/${moduleName} ${PACKAGE_PATH}/module/${module}." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
                unzip -o -d ${DEPLOY_APPS_PLUGINS_PATH}/${moduleName} ${PACKAGE_PATH}/module/${module}
                if [ $? -ne 0 ]; then
                    printMessageLog ERROR "unzip -o -d ${DEPLOY_APPS_PLUGINS_PATH}/${moduleName} ${PACKAGE_PATH}/module/${module} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
                    continue
                else
                    printMessageLog INFO "unzip -o -d ${DEPLOY_APPS_PLUGINS_PATH}/${moduleName} ${PACKAGE_PATH}/module/${module} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
                fi
            fi        
        fi
    done
    
    # 复制依赖包
    rsync -a -r ${PACKAGE_PATH}/core/*.jar ${DEPLOY_APPS_CORE_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    [[ $? -ne 0 ]] && return 1
    
    # 复制版本号
    printMessageLog INFO "copy version file." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    rsync -a -r ${PACKAGE_PATH}/version ${DEPLOY_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1

    if [ $? -ne 0 ]; then
        printMessageLog WARN "copy file failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO} 
        return 1
    fi
    
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
    printMessageLog WARN "setPermission starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    chmod -R 755 ${DEPLOY_PATH}/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    chmod 744 ${DEPLOY_PATH}/bin/launcher >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    chmod 744 ${DEPLOY_PATH}/bin/*.sh >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    chmod 744 ${DEPLOY_PATH}/*/*.jar >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    chmod 644 ${DEPLOY_PATH}/conf/*.properties >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    chmod 744 ${DEPLOY_APPS_CORE_PATH}/*.jar >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    chmod 744 ${DEPLOY_APPS_PLUGINS_PATH}/*/*.jar >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    chmod 644 ${DEPLOY_APPS_CONF_PATH}/*.properties >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    chmod 644 ${DEPLOY_APPS_CONF_PATH}/indexValidation/*.xml >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    printMessageLog WARN "setPermission end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog WARN "setConfigFile() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 蓝鲸平台mysql配置
    modifyConfig "bdp.mysql.host" ${BW_MYQL_DB_HOST} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    modifyConfig "bdp.mysql.db" ${BW_MYQL_DB_DBNAME} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    modifyConfig "bdp.mysql.user" ${BW_MYQL_DB_USER} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    modifyConfig "bdp.mysql.password" ${BW_MYQL_DB_PASSWD} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    
    # 业务库mysql配置
    local mysql_url="jdbc:mysql://${CLUSTER_MYQL_DB_HOST}:3306/${CLUSTER_MYQL_DB_DBNAME}"
    modifyConfig "option.db.mysql.url" ${mysql_url} ${SDKWS_CONFIG_FILE_PATH}
    modifyConfig "option.db.mysql.user" ${CLUSTER_MYQL_DB_USER} ${SDKWS_CONFIG_FILE_PATH}
    modifyConfig "option.db.mysql.pwd" ${CLUSTER_MYQL_DB_PASSWD} ${SDKWS_CONFIG_FILE_PATH}
    
    # zookeeper配置
    modifyConfig "bdp.zookeeper.quorum" ${ZOOKEEPER_HOST} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    
    # kafka配置
    modifyConfig "bdp.kafka.bootstrap.servers" ${KAFKA_HOST} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    
    # es配置: 配置文件bluewhale-site.properties
    modifyConfig "bdp.es.cluster.name" ${ES_CLUSTER_NAME} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    modifyConfig "bdp.es.http.servers" ${ES_HTTP_HOST} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    modifyConfig "bdp.es.tcp.servers" ${ES_TCP_HOST} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    # es配置: 配置文件sdkws.properties
    modifyConfig "option.es.cluster.name" ${ES_CLUSTER_NAME} ${SDKWS_CONFIG_FILE_PATH}
    modifyConfig "option.es.http.servers" ${ES_HTTP_HOST} ${SDKWS_CONFIG_FILE_PATH}
    modifyConfig "option.es.tcp.servers" ${ES_TCP_HOST} ${SDKWS_CONFIG_FILE_PATH}
    
    # kylin配置
    modifyConfig "bdp.kylin.url" ${KYLIN_URL} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    modifyConfig "bdp.kylin.user" ${KYLIN_USER} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    modifyConfig "bdp.kylin.password" ${KYLIN_PASSWORD} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    
    # presto配置
    modifyConfig "bdp.presto.url" ${PRESTO_URL} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    modifyConfig "bdp.presto.user" ${PRESTO_USER} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    modifyConfig "bdp.presto.password" ${PRESTO_PASSWD} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}

    # presto配置
    modifyConfig "bdp.neo4j.url" ${NEO4J_URL} ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    
    # redis配置-框架配置文件
    isContain ${NN_REDIS_HOST} ":"
    if [ $? -ne 0 ]; then
        modifyConfig "bdp.redis.server" "${NN_REDIS_HOST}:${NN_REDIS_PORT}" ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    else
        modifyConfig "bdp.redis.server" "${NN_REDIS_HOST}" ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    fi
    modifyConfig "bdp.redis.password" "${NN_REDIS_PASSWD}" ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    
    # redis配置-应用服务配置文件
    isContain ${NN_REDIS_HOST} ":"
    if [ $? -ne 0 ]; then
        modifyConfig "realtimeRedis" "${NN_REDIS_HOST}:${NN_REDIS_PORT}" ${SDKWS_CONFIG_FILE_PATH}
    else
        modifyConfig "realtimeRedis" "${NN_REDIS_HOST}" ${SDKWS_CONFIG_FILE_PATH}
    fi
    modifyConfig "realtimeRedisPwd" "${NN_REDIS_PASSWD}" ${SDKWS_CONFIG_FILE_PATH}
   
    # 配置映射文件
    modifyConfig "type.map.path" "${DEPLOY_APPS_CONF_PATH}/typeMap.json" ${SDKWS_CONFIG_FILE_PATH}
    
    # 配置kylin默认平台ID
    modifyConfig "default_platform_id" "${DEFAULT_PLATFORM_ID}" ${SDKWS_CONFIG_FILE_PATH}
    
    # 格式化配置文件为unix格式
    dos2unix ${SDKWS_CONFIG_FILE_PATH}
    dos2unix ${BLUEWHALE_SITE_CONFIG_FILE_PATH}
    
    printMessageLog WARN "setConfigFile() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		setSoftLink
# createTime  :		2019-01-04
# description :		软链接配置
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function setSoftLink()
{
    printMessageLog WARN "setSoftLink() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 软链接应用服务包到apps目录下
    printMessageLog INFO "set apps plugins links." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    [[ ! -d ${DEPLOY_PATH}/apps/ ]] && mkdir -p ${DEPLOY_PATH}/apps/ || rm -r -f ${DEPLOY_PATH}/apps/*
    
    printMessageLog INFO "set link: ln -s ${DEPLOY_VERSION_PATH} ${DEPLOY_PATH}/apps/${VERSION_NUMBER}." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    ln -s ${DEPLOY_VERSION_PATH} ${DEPLOY_PATH}/apps/${VERSION_NUMBER} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ] ;then 
        printMessageLog ERROR "set apps plugins links failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 软链接hadoop配置文件到应用服务目录下
    printMessageLog INFO "set hadoop conf links." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    ln -s ${HADOOP_CONF_PATH}/core-site.xml ${DEPLOY_PATH}/apps/${VERSION_NUMBER}/conf/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    ln -s ${HADOOP_CONF_PATH}/hdfs-site.xml ${DEPLOY_PATH}/apps/${VERSION_NUMBER}/conf/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ] ;then 
        printMessageLog ERROR "set hadoop conf links failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog WARN "setSoftLink() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

main $*
