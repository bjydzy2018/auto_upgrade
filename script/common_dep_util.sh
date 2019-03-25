#!bin/bash

CLASS_NAME=$(basename $0)
CUR_PATH=$(cd "$(dirname "$0")";pwd)
PACKAGE_PATH=${CUR_PATH}/..
PARENT_PATH_NAME=""

# 日志路径
LOG_PATH=""
LOG_FILE_NAME=""
readonly LOG_ROOT_PATH=/var/log/sdk_vbs
# 日志颜色
RED_COLOR='\E[1;31m'  
YELOW_COLOR='\E[1;33m' 
BLUE_COLOR='\E[1;34m'  
RESET='\E[0m'

# 部署路径
readonly DEPLOY_ROOT_PATH=/opt/sdk_vbs
# 组件备份路径
readonly BACKUP_ROOT_PATH=/opt/sdk_vbs/backup
# nginx部署路径
readonly NGINX_PATH=/usr/local/nginx
# php部署路径
readonly PHP_PATH=/usr/local/php
# web服务目录
readonly WWW_PATH=/data/starcor/www
# crontab路径
readonly CRONTAB_PATH=/var/spool/cron/root
# /etc/hosts
readonly HOSTS_PATH=/etc/hosts
# HDFS路径
readonly HIVE_DATA_PATH=/user/hive/warehouse
# 老接口服务部署路径
readonly SDK_WS_DEPLOY_PATH=/cluster
# Hadoop配置文件路径
readonly HADOOP_CONF_PATH=/etc/hadoop/conf

# 组件名称定义
readonly REPORTER_SYSTEM_NAME="reporter_system"
readonly SDK_WS_NAME="sdk_ws"
readonly VBS_WS_NAME="vbs_ws"
readonly CREATE_GX_NAME="create_gx"
readonly USER_PROFILE_NAME="user_profile"
readonly WS_OUTFILE_NAME="ws_outfile"
readonly DATA_INTEGRATION_NAME="data_integration"
readonly REALTIME_ENGINE_NAME="realtime_engine"
readonly LOGMGR_NAME="logmgr"
readonly DATA_MODEL_SERVICE_NAME="data_model_service"
readonly META_LOAD_NAME="meta_load"
readonly STREAMING_LOAD_NAME="streaming_load"
# 微服务名称
MICRO_SERVICE_NAME=""
# 版本号
VERSION_NUMBER=""

# 部署文件路径，该文件路径可变，适配开发测试环境，禁止改为readonly
DEPLOY_FILE_PATH=${CUR_PATH}/param.ini
# 默认部署文件路径
readonly DEFAULT_DEPLOY_FILE_PATH=${CUR_PATH}/default.ini
# 公共参数section
readonly COMMON_SECTION="common_params"
# 报表服务器crontab section
readonly CRONTAB_SECTION="crontab_list"

# ----------------------------------------------------------------------
# 部署公共参数
# ----------------------------------------------------------------------
# cms数据库地址，支持扩展，无配置项自动添加
NL_CMS_DB_HOST=""
# cms数据库账户
NL_CMS_DB_USER=""
# cms数据库密码
NL_CMS_DB_PASS=""
# cms数据库名称
NL_CMS_DB_NAME=""
# cms SP_ID
NL_CMS_SP_ID=""
# cms 平台ID
NL_CMS_PLATFORM_ID=""
# AAA数据库地址
NL_AAA_DB_HOST=""
# AAA数据库账户
NL_AAA_DB_USER=""
# AAA数据库密码
NL_AAA_DB_PASS=""
# AAA数据库名称
NL_AAA_DB_NAME=""
# 元数据上传FTP地址
HADOOP_FTP_HOST=""
# 元数据上传FTP账户
HADOOP_FTP_USER=""
# 元数据上传FTP密码
HADOOP_FTP_PWD=""
# 元数据上传FTP路径
HADOOP_FTP_DIRECTORY=""
# redis地址（所有redis统一）
NN_REDIS_HOST=""
# redis端口
NN_REDIS_PORT=""
# redis密码
NN_REDIS_PASSWD=""
# kafka队列地址，多IP用分号分隔
KAFKA_HOST=""
# kafka主机映射配置，在cdh查询
KAFKA_HOSTNAMES=""
# ES主机地址
ES_HOST=""
# ES TCP主机地址，需要动态拼接
ES_TCP_HOST=""
# ES HTTP主机地址，需要动态拼接
ES_HTTP_HOST=""
# ES TCP端口
ES_TCP_PORT=""
# ES HTTP端口
ES_HTTP_PORT=""
# ES集群名称
ES_CLUSTER_NAME=""
# neo4j url地址
NEO4J_URL=""
# kylin url地址
KYLIN_URL=""
# kylin 用户名
KYLIN_USER=""
# kylin 密码
KYLIN_PASSWORD=""
# zookeeper 地址:端口
ZOOKEEPER_HOST=""

# ----------------------------------------------------------------------
# 报表平台部署参数
# ----------------------------------------------------------------------
# 大数据请求webservice地址
NL_WEBSERVICE=""
# 个性化推荐老接口
NL_RECOMMEND_SERVICE=""
# 个性化推荐新接口
NL_NEW_RECOMMEND_SERVICE_ALI=""
# 大数据详单导出地址
NL_DOWNLOAD_WEBSERVICE=""
# 超级管理员账户
SYS_LOGINID=""
# 超级管理员密码
SYS_LOGINPWD=""
# 报表管理MySQL数据库地址
NL_DB_HOST=""
# 报表管理MySQL数据库账户
NL_DB_USER=""
# 报表管理MySQL数据库密码
# @TODO 需要处理密码种包含的空格问题
NL_DB_PASS=""
# 报表管理MySQL数据库名称
NL_DB_NAME=""
# 运营商ID
NL_SP_ID=""
# Hive数据库平台ID
HIVE_PLATFORM_ID=""
# 博瑞得：智能推荐接口
NN_BRD_URL=""
# 定时器任务列表
CRONTAB_LIST=""
# 是否需要开启通过IP地址匹配地区，目前只有新疆CBC需要开启（即true）
IF_IP_2_LATITUDE=""
# 地区码是否转换参数，贵州和内蒙古广电配置1，新疆配置2，其他地区若不需要转换则配置0
AREA_CODE_CHANGE_RULE=""
# 是否在错误码和页面ID前拼接sp_id，内蒙古需要配置为true，其他地区根据需求配置
IS_SPLICE_SP_ID=""

# ----------------------------------------------------------------------
# 数据模型服务部署参数
# ----------------------------------------------------------------------
# 蓝鲸平台MySQL数据库地址
BW_MYQL_DB_HOST=""
# 蓝鲸平台MySQL数据库账户
BW_MYQL_DB_USER=""
# 蓝鲸平台MySQL数据库密码
BW_MYQL_DB_PASSWD=""
# 蓝鲸平台MySQL数据库名称
BW_MYQL_DB_DBNAME=""
# 集群数据MySQL数据库地址
CLUSTER_MYQL_DB_HOST=""
# 集群数据MySQL数据库账户
CLUSTER_MYQL_DB_USER=""
# 集群数据MySQL数据库密码
CLUSTER_MYQL_DB_PASSWD=""
# 集群数据MySQL数据库名称
CLUSTER_MYQL_DB_DBNAME=""

# ----------------------------------------------------------------------
# 接口服务部署参数
# ----------------------------------------------------------------------
# 数据库入库地址
GRAPHX_URL=""
# PRESTO数据库连接地址，判断是否以jdbc:presto开头，若是，直接写入，若不是需要拼接
PRESTO_URL=""
# PRESTO数据库账户
PRESTO_USER=""
# PRESTO数据库密码
PRESTO_PASSWD=""
# kylin默认视图库
DEFAULT_PLATFORM_ID=""

# ----------------------------------------------------------------------
# FunctionName:        showBanner
# createTime  :        2019-03-13
# description :        显示状态标志
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function showBanner(){
    echo "#####################################################################################"
    echo "#                                                                                   #"
    echo "#  ███████╗ ╔████████╗      ╔██╗        ████████╗ ╔████████╗ ╔████████╗  ████████╗  #"
    echo "#  ██╔════╝ ╚══╗██╔══╝     ╔████╗       ██╔═════╝ ║██╔══╗██║ ║██    ██║  ██╔═════╝  #"
    echo "#  ██╚════╗    ║██║       ╔██  ██╗      ██║       ║██║  ║██║ ║████████║  ██╚═════╗  #"
    echo "#  ███████║    ║██║      ╔████████╗     ██║       ║██║  ║██║ ║██ ██═══╝  ████████║  #"
    echo "#       ██║    ║██║     ╔██      ██╗    ██║       ║██║  ║██║ ║██  ██╗    ██╔═════╝  #"
    echo "#       ██║    ║██║    ╔██        ██╗   ██╚═════╗ ║██╚══╝██║ ║██   ██╗   ██╚═════╗  #"
    echo "# ╔███████║    ║██║   ╔██╗        ╔██╗ ╔████████║ ║████████║ ║██╗  ╔██╗ ╔████████║  #"
    echo "# ╚═══════╝    ╚══╝   ╚══╝        ╚══╝ ╚════════╝ ╚════════╝ ╚══╝  ╚══╝ ╚════════╝  #"
    echo "#                                                                                   #"
    echo "#####################################################################################"
}

# ----------------------------------------------------------------------
# FunctionName:        initLog
# createTime  :        2018-08-10
# description :        初始化日志文件
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function initLog()
{
    componentName=$1
    LOG_FILE_NAME=$2

    if [ -z ${componentName} ]; then
        echo "component name is null, invalid."
        exit 1
    fi
    
    # 获取微服务名称
    getMicroServiceName ${componentName}
    
    # 初始化版本号
    VERSION_NUMBER=$(getVersionNumber ${PACKAGE_PATH}/version)

    LOG_PATH=${LOG_ROOT_PATH}/${componentName}/script
    RUN_LOG_PATH=${LOG_ROOT_PATH}/${componentName}/run
    ACCESS_LOG_PATH=${LOG_ROOT_PATH}/${componentName}/access

    if [ ! -d ${LOG_PATH} ]; then
        mkdir -p ${LOG_PATH}
        mkdir -p ${RUN_LOG_PATH}
        mkdir -p ${ACCESS_LOG_PATH}
    fi

    if [ ! -f ${LOG_PATH}/${LOG_FILE_NAME} ]; then
        touch ${LOG_PATH}/${LOG_FILE_NAME}
    else
        cat /dev/null > ${LOG_PATH}/${LOG_FILE_NAME}
    fi

    chmod -R 755 ${LOG_PATH}
    chmod -R 755 ${RUN_LOG_PATH}
    chmod -R 755 ${ACCESS_LOG_PATH}
    chmod 640 ${LOG_PATH}/${LOG_FILE_NAME}
}

# ----------------------------------------------------------------------
# FunctionName:        printMessageLog
# createTime  :        2018-08-10
# description :        输出日志到日志文件和屏幕显示
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function printMessageLog()
{
    local logLevel=$1
    local message=$2
    local className=$3
    local funcName=$4
    local lineNo=$5
    local color=$6

    if [ -z ${lineNo} ]; then
        lineNo=$4
        funcName=" "
    fi

    local currenttime=`date "+%Y-%m-%d %H:%M:%S"`
    
    echo "[${logLevel}][${currenttime}][${className}|${funcName}|LINENO:${lineNo}][${message}]" >> ${LOG_PATH}/${LOG_FILE_NAME}
    if [ -z "${color}" ]; then
        echo "[${logLevel}][${currenttime}][${className}|${funcName}|LINENO:${lineNo}][${message}]"
    else
        echo -e "[${logLevel}][${currenttime}][${className}|${funcName}|LINENO:${lineNo}][${color}${message}${RESET}]"
    fi
}

# ----------------------------------------------------------------------
# FunctionName:		PrintMessageFile
# createTime  :		2018-08-09
# description :		打印日志到日志文件但不在屏幕显示
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function printMessageFile()
{
    local logLevel=$1
    local message=$2
    local className=$3
    local funcName=$4
    local lineNo=$5
    
    if [ -z ${lineNo} ]; then
        lineNo=$4
        funcName=" "
    fi
    
    local currentTime=`date "+%Y-%m-%d %H:%M:%S"`

    echo "[${logLevel}][${currentTime}][${className}|${funcName}|LINENO:${lineNo}][${message}]" >> ${LOG_PATH}/${LOG_FILE_NAME}
}

# ----------------------------------------------------------------------
# FunctionName:        getVersionNumber
# createTime  :        2018-08-28
# description :        初始化版本号,从version文件中获取版本号
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function getVersionNumber()
{
    local filePath=$1
    
    if [ ! -f ${filePath} ]; then
        echo "[ERROR] ${filePath} no such file."
        exit 1
    fi

    dos2unix ${filePath}
    
    local value=$(readConfig "version" ${filePath})
    if [ -z ${value} ]; then
        echo "get version number failed."
        exit 1
    else
        isStartWith ${value} "v"
        if [ $? -ne 0 ]; then
            value="v"${value}
        fi
    fi
    
    echo ${value}
}

# ----------------------------------------------------------------------
# FunctionName:        getMicroServiceName
# createTime  :        2018-08-21
# description :        根据组件名称，获取微服务名称
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function getMicroServiceName()
{
    componentName=$1
    if [ -z ${componentName} ]; then
        printMessageLog ERROR "compenent name is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi

    if [ ${componentName} = ${REPORTER_SYSTEM_NAME} ]; then
        MICRO_SERVICE_NAME="VisualPlatformWebsite"
    elif [ ${componentName} = ${SDK_WS_NAME} -o  ${componentName} = ${VBS_WS_NAME} ]; then
        MICRO_SERVICE_NAME="DataQueryService"
    elif [ ${componentName} = ${CREATE_GX_NAME} -o   ${componentName} = ${USER_PROFILE_NAME} -o   ${componentName} = ${WS_OUTFILE_NAME} -o   ${componentName} = ${DATA_INTEGRATION_NAME} -o   ${componentName} = ${REALTIME_ENGINE_NAME} -o   ${componentName} = ${LOGMGR_NAME} -o   ${componentName} = ${DATA_MODEL_SERVICE_NAME} -o  ${componentName} = ${META_LOAD_NAME} -o  ${componentName} = ${STREAMING_LOAD_NAME} ]; then
        MICRO_SERVICE_NAME="PlatformBasicAPIService"
    else
        printMessageLog ERROR "unknow compenent name is, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
}

# ----------------------------------------------------------------------
# FunctionName:		readIniFile
# createTime  :		2018-08-21
# description :		读取ini配置文件
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function readIniFile()
{
    if [ $# -lt 3 ]; then
        printMessageLog ERROR "parameter is invalid, at least 3 parameters, which contain file path, section and item." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        exit 1
    fi
    local iniFilePath=$1
    local section=$2
    local item=$3
    
    if [ ! -f ${iniFilePath} ]; then
        printMessageLog ERROR "File ${iniFilePath} is not exist." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        exit 1
    fi

    local value=`awk -F '=' '/\['${section}'\]/{a=1}a==1&&$1~/'${item}'/{print $2;exit}' ${iniFilePath}`

    echo ${value}
}

# ----------------------------------------------------------------------
# FunctionName:		writeIniFile
# createTime  :		2018-08-21
# description :		修改ini配置文件
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function writeIniFile()
{
    if [ $# -lt 4 ]; then
        printMessageLog ERROR "parameter is invalid, at least 4 parameters, which contain file path, section, item and value." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        exit 1
    fi
    local iniFilePath=$1
    local section=$2
    local item=$3
    local newValue=$4

    if [ ! -f ${iniFilePath} ]; then
        printMessageLog ERROR "File ${iniFilePath} is not exist." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        exit 1
    fi

    local value=`sed -i "/^\[${section}\]/,/^\[/ {/^\[${section}\]/b;/^\[/b;s/^${item}*=.*/${item}=${newValue}/g;}" ${iniFilePath}`

    echo ${value}
}

# ----------------------------------------------------------------------
# FunctionName:		modifyConfig
# createTime  :		2018-08-21
# description :		修改key=value类型的配置文件
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function modifyConfig()
{
    local key=$1
    local value=$2
    local configFile=$3
    
    if [ -z ${configFile} ]; then
        printMessageLog ERROR "${configFile} is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    if [ ! -f ${configFile} ];then
        printMessageLog ERROR "${configFile} does not exist." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog INFO "grep \"^\s*${key}\s*=\" ${configFile}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    local isExist=$(grep "^\s*${key}\s*=" ${configFile})
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "get ${key} from ${configFile} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi    
    if [ -z "${isExist}" ]; then
        printMessageLog INFO "add key: \"^\s*${key}\s*=\" ${configFile}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        echo "${key}=${value}" >> ${configFile}
    else
        printMessageLog INFO "modify key: \"^\s*${key}\s*=\" ${configFile}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        sed -i "s#^\s*${key}\s*=.*#${key}=${value}#g" ${configFile}
    fi

    if [ $? -ne 0 ]; then
        printMessageLog ERROR "update ${configFile} set ${key}=${value} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog INFO "update ${configFile} set ${key}=${value} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		readConfig
# createTime  :		2018-08-21
# description :		读取配置文件中某个key的值
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function readConfig()
{
    local key=$1
    local configFile=$2
    local value=

    if [ ! -f ${configFile} ];then
        printMessageLog ERROR "${configFile} does not existed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        exit 1
    fi
    
    value=`awk -F'=' '{if($1~/'${key}'/) print $2}' ${configFile}`

    echo ${value}
}

# ----------------------------------------------------------------------
# FunctionName:		modifyPHPPlatform
# createTime  :		2018-08-10
# description :		修改version.php配置文件中平台id信息
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function modifyPHPPlatform()
{
    local platformID=$1
    local mapName=$2
    local mpaRegionCode=$3
    local configFile=$4

    if [ ! -f ${configFile} ];then
        printMessageLog ERROR "${configFile} does not exist." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    # 匹配全数组正则：(\"gzgd\"\s*\=\>\s*array\(\s*\"map\" \=\>\s*\"guizhou\",\s*\"map_code\"\s*\=\>\s*\"156520\",\s*\))
    
    local isExist=$(grep "\"${platformID}\"\s*\=>\s*array\s*(" "${configFile}")
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "get ${platformID} from ${configFile} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    elif [ -z "${isExist}" ];then
        echo "${key}=${value}" >> "${configFile}"
    else
        sed -i "s#^\s*${key}\s*=.*#${key}=${value}#g" "${cofigFile}"
    fi

    if [ $? -ne 0 ]; then
        printMessageLog ERROR "get ${key} from ${configFile} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog INFO "get ${key} from ${configFile} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		readPHPConfig
# createTime  :		2018-08-10
# description :		读取version.php文件中的version号
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function readPHPConfig()
{
    local key=$1
    local configFile=$2
    local value=

    if [ ! -f ${configFile} ];then
        printMessageLog ERROR "${configFile} does not exist." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    value=$(awk -F \" '/'${key}'/{print $4}' ${configFile})
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "get ${key} from ${configFile} file failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        exit 1
    elif [ -z ${value} ]; then
        # 兼容PHP文件中的单引号，但是建议全部规范为双引号，以免解析出错
        value=$(awk -F \' '/'${key}'/{print $2}' ${configFile})
    fi

    echo ${value}
}

# ----------------------------------------------------------------------
# FunctionName:        modifyXMLConfig
# createTime  :        2018-08-21
# description :        修改xml文件
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function modifyXMLConfig()
{
    local attribute=$1
    local value=$2
    local filePath=$3

    if [ ! -f ${filePath} ]; then
        printMessageLog ERROR "file path is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    # 修改xml文件
    printMessageLog DEBUG "sed -i \"s/<${attribute}>.*<\/${attribute}>/<${attribute}>${value}<\/${attribute}>/g\" ${filePath}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    sed -i "s/<${attribute}>.*<\/${attribute}>/<${attribute}>${value}<\/${attribute}>/g" ${filePath}
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "update file ${filePath} set ${attribute}=${value} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        modifyPhpConfig
# createTime  :        2018-08-27
# description :        修改PHP文件
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function modifyPhpConfig()
{
    local filePath=$1
    local attribute=$2
    local value=$3

    if [ -z "${filePath}" ]; then
        printMessageLog ERROR "file path is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    if [ ! -f ${filePath} ]; then
        printMessageLog ERROR "${filePath} no such file, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    # 修改xml文件
    local isExist=$(grep "^define(\"${attribute}\"" "${filePath}")
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "get ${attribute} from ${filePath} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    elif [ -z "${isExist}" ]; then
        # 适配单引号的配置项
        local isSingleExist=$(grep "^define(\'${attribute}\'" "${filePath}")
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "get ${attribute} from ${filePath} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        elif [ -z "${isSingleExist}" ]; then
            echo ""  >> ${filePath}
            echo "define(\"${attribute}\", \"${value}\");" >> ${filePath}
        else
            sed -i "s#\s*\"${attribute}\".*#\"${attribute}\", \"${value}\");#g" "${filePath}"
        fi    
    else
        sed -i "s#\s*\"${attribute}\".*#\"${attribute}\", \"${value}\");#g" "${filePath}"
    fi
    
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "update file ${filePath} set ${attribute}=${value} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        isStartWith
# createTime  :        2018-08-22
# description :        判断字符串是否以某个字符串开头
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function isStartWith()
{
    local string=$1
    local start=$2

    if [[ "${string}" =~ ^${start}.* ]]; then
        return 0
    fi

    return 1
}

# ----------------------------------------------------------------------
# FunctionName:        isEndWith
# createTime  :        2018-08-22
# description :        判断字符串是否以某个字符串结束
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function isEndWith()
{
    local string=$1
    local end=$2

    if [[ "${string}" =~ ${end}$ ]]; then
        return 0
    fi

    return 1
}

# ----------------------------------------------------------------------
# FunctionName:        isContain
# createTime  :        2018-08-22
# description :        判断字符串是否包含某个字符串
# author      :        wenfeng.duan
# return      :        0:包含, 1:不包含
# ----------------------------------------------------------------------
function isContain()
{
    local string=$1
    local contain=$2

    [[ "${string}" =~ "${contain}" ]] && return 0 || return 1
}

# ----------------------------------------------------------------------
# FunctionName:        isFileContain
# createTime  :        2018-12-25
# description :        判断文件是否包含某个字符串
# author      :        wenfeng.duan
# return      :        0:包含, 1:不包含
# ----------------------------------------------------------------------
function isFileContain()
{
    local filePath=$1
    local contain=$2
    
    grep -c "${contain}" ${filePath}

    [[ $? -ne 0 ]] && return 0 || return 1
}

# ----------------------------------------------------------------------
# FunctionName:		toUpper
# createTime  :		2018-08-12
# description :		字符串大写转换
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function toUpper()
{
    local str=$1
    
    if [ -z ${str} ]; then
        return 0
    fi
    
    return $(echo ${str} | tr [a-z] [A-Z])
}

# ----------------------------------------------------------------------
# FunctionName:		toLower
# createTime  :		2018-08-10
# description :		字符串小写转换
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function toLower()
{
    local str=$1
    
    if [ -z ${str} ]; then
        return 0
    fi
    
    return $(echo ${str} | tr [A-Z] [a-z])
}

# ----------------------------------------------------------------------
# FunctionName:		isExistNginx
# createTime  :		2018-08-24
# description :		Nginx是否安装判断
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function isExistNginx()
{
    local isRpmExist=$(rpm -qa | grep nginx)
    
    if [ -z ${isRpmExist} ]; then
        local isPathExist=$(echo \$PATH | grep nginx)
        if [ -z ${isPathExist} ]; then
            local nginxFile=/usr/local/nginx/sbin/nginx
            if [ ! -f ${nginxFile} ]; then
                return 1
            fi
        fi
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		isExistPHP
# createTime  :		2018-08-24
# description :		PHP是否安装判断
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function isExistPHP()
{
    local isRpmExist=$(rpm -qa | grep php)
    
    if [ -z ${isRpmExist} ]; then
        local isPathExist=$(echo \$PATH | grep php)
        if [ -z ${isPathExist} ]; then
            local phpFile=/usr/local/php/sbin/php-fpm
            if [ ! -f ${phpFile} ]; then
                return 1
            fi
        fi
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		isExistJRE
# createTime  :		2018-08-24
# description :		JRE是否安装判断
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function isExistJRE()
{
    java -version
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		isExistMySQL
# createTime  :		2018-08-24
# description :		MySQL是否安装判断
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function isExistMySQL()
{
    if [ $# -lt 3 ]; then
        printMessageLog ERROR "At least 3 parameters, including host address, user name, password."  ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    local host=$1
    local username=$2
    local passwd=$3
    
    mysql -h${host} -u${username} -p${passwd} -e "show databases;" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		isExistMySQLDatabase
# createTime  :		2019-03-11
# description :		MySQL中数据库是否已经存在
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function isExistMySQLDatabase()
{
    if [ $# -lt 3 ]; then
        printMessageLog ERROR "At least 3 parameters, including host address, user name, password."  ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    local host=$1
    local username=$2
    local passwd=$3
    local database=$4
    
    mysql -h${host} -u${username} -p${passwd} -D${database} -e "show tables;" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		isExistHive
# createTime  :		2018-08-24
# description :		Hive是否安装判断
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function isExistHive()
{
    local dbname=$1
    local hivePath=""
    
    if [ -z ${dbname} ]; then
        hivePath=${HIVE_DATA_PATH}
    else
        hivePath=${HIVE_DATA_PATH}/${dbname}.db/
    fi
    
    hdfs dfs -test -e ${hivePath} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    if [ $? -ne 0 ]; then 
        printMessageLog ERROR "hdfs file path ${hivePath} is not exist." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1;
    fi
    
    printMessageLog INFO "hdfs file path ${hivePath} is existed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		isExistReportSysytem
# createTime  :		2018-08-24
# description :		可视化平台是否安装判断
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function isExistReportSysytem()
{
    # 组件新部署目录
    reportSysytemDeployPath=${WWW_PATH}/bigdata
    
    if [ ! -f ${reportSysytemDeployPath}/version.php ]; then
        printMessageLog ERROR "${REPORTER_SYSTEM_NAME} haven't install."  ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    local versionNumber=$(readPHPConfig "PLANT_VERSION" ${reportSysytemDeployPath}/version.php)
    local curNO=$(echo ${VERSION_NUMBER:0})
    local reportNO=$(echo ${versionNumber:0})
    
    if [ ${curNO} > ${reportNO} ]; then
        printMessageLog ERROR "${REPORTER_SYSTEM_NAME} haven't upgrade."  ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		isExistDos2unix
# createTime  :		2019-01-16
# description :		判断是否安装dos2unix命令
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function isExistDos2unix()
{
    local help=$(rpm -qa | grep dos2unix)
    if [ -z "${help}" ]; then
        printMessageLog INFO "yum -y install dos2unix"  ${CLASS_NAME} ${FlUNCNAME} ${LINENO}
        yum -y install dos2unix
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "install dos2unix failed."  ${CLASS_NAME} ${FlUNCNAME} ${LINENO}
            return 1
        else
            printMessageLog INFO "install dos2unix successfully."  ${CLASS_NAME} ${FlUNCNAME} ${LINENO}
        fi
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		isExistRsync
# createTime  :		2019-01-16
# description :		判断是否安装rsync命令
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function isExistRsync()
{
    local help=$(rpm -qa | grep rsync)
    if [ -z "${help}" ]; then
        printMessageLog INFO "yum -y install rsync"  ${CLASS_NAME} ${FlUNCNAME} ${LINENO}
        yum -y install rsync
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "install rsync failed."  ${CLASS_NAME} ${FlUNCNAME} ${LINENO}
            return 1
        else
            printMessageLog INFO "install rsync successfully."  ${CLASS_NAME} ${FlUNCNAME} ${LINENO}
        fi
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		isExistUnzip
# createTime  :		2019-01-16
# description :		判断是否安装uznip命令
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function isExistUnzip()
{
    local help=$(rpm -qa | grep unzip)
    if [ -z "${help}" ]; then
        printMessageLog INFO "yum -y install unzip"  ${CLASS_NAME} ${FlUNCNAME} ${LINENO}
        yum -y install unzip
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "install unzip failed."  ${CLASS_NAME} ${FlUNCNAME} ${LINENO}
            return 1
        else
            printMessageLog INFO "install unzip successfully."  ${CLASS_NAME} ${FlUNCNAME} ${LINENO}
        fi
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		isExistBluewhale
# createTime  :		2019-01-16
# description :		判断是否安装蓝鲸调度平台Bluewhale
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function isExistBluewhale()
{
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		isExistKylin
# createTime  :		2019-01-31
# description :		判断是否安装Kylin
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function isExistKylin()
{
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		getPythonVersion
# createTime  :		2018-12-25
# description :		获取python版本号
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function getPythonVersion()
{
    # 获取版本号
    local pythonVersion=`python -V 2>&1 | awk '{print $2}'`
    
    if [ -z ${pythonVersion} ]; then
        printMessageLog INFO "haven't install python."  ${CLASS_NAME} ${FlUNCNAME} ${LINENO}
        return 1
    fi
    
    echo "${pythonVersion}"
}

# ----------------------------------------------------------------------
# FunctionName:        backupFile
# createTime  :        2018-08-23
# description :        组件部署成功后备份部署包，用于回滚
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function backupFile()
{
    local sourceFile=$1
    local targetPath=$2
    local type=$3
    
    # 判断组件备份路径是否存在
    if [ ! -d ${targetPath} ]; then
        printMessageLog WARN "${targetPath} is not exists, create it." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        mkdir -p ${targetPath} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "create ${targetPath} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
        
        chmod -R 755 ${targetPath}
    else
        # 仅保留目录下最新的两个文件,其他删除
        cd ${targetPath}
        if [ $(ls -l | grep "*.${type}" | wc -l) -ge 3 ]; then
            printMessageLog WARN "more than 2 package files in ${targetPath}." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            rm -rf $(ls -rt | head -n2)
        fi
        
        # 备份当前组件包到备份目录
        printMessageLog DEBUG "rsync -a -r ${sourceFile} ${targetPath}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        rsync -a -r ${sourceFile} ${targetPath} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        [ $? -ne 0 ] && return 1
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		getPackageName
# createTime  :		2018-08-24
# description :		获取当前部署包名称
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function getPackageName()
{
    cd ${PACKAGE_PATH}
    
    local moduleName=$(pwd | awk -F "/" '{print $NF}')
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "get component package name failed."  ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    PARENT_PATH_NAME=${moduleName}.tar.gz
    
    cd ${CUR_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    echo ${PARENT_PATH_NAME}
}

# ----------------------------------------------------------------------
# FunctionName:        backupPackage
# createTime  :        2018-08-23
# description :        组件部署成功后备份部署包，用于回滚
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function backupPackage()
{
    local componentName=$1
    if [ -z ${componentName} ]; then
        printMessageLog ERROR "component name is null, invali." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    printMessageLog INFO "backupPackage ${componentName} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 获取包名称
    local packageName=$(getPackageName)
    if [ $? -eq 1 ]; then
        printMessageLog ERROR "get component package name failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    local soureFile=${CUR_PATH}/../../${packageName}
    local targePath=${BACKUP_ROOT_PATH}/${componentName}
    
    backupFile ${soureFile} ${targePath} "tar.gz"
    if [ $? -ne 0 ]; then
        return 1
    else
        return 0
    fi
}

# ----------------------------------------------------------------------
# FunctionName:        getToday
# createTime  :        2018-08-24
# description :        获取当前日期，格式：yyyymmdd
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function getToday()
{
    today=$(date +'%Y%m%d')
    
    echo ${today}
}

# ----------------------------------------------------------------------
# FunctionName:        getCurrentTime
# createTime  :        2018-08-24
# description :        获取当前日期，格式：yyyymmdd
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function getCurrentTime()
{
    currentTime=$(date +'%Y%m%d%H%M%S')
    
    echo ${currentTime}
}

# ----------------------------------------------------------------------
# FunctionName:        readDeployParams
# createTime  :        2018-08-23
# description :        组件部署参数读取
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function readDeployParams()
{
    printMessageLog INFO "readDeployParams ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 公共参数获取
    readCommonParams

    # 组件参数获取
    readComponentParams

    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        readCommonParams
# createTime  :        2018-08-23
# description :        组件部署公共参数读取
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function readCommonParams()
{
    printMessageLog INFO "readCommonParams ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    printMessageLog DEBUG "DEPLOY_FILE_PATH=${DEPLOY_FILE_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}

    dos2unix ${DEPLOY_FILE_PATH}
    
    # 公共参数获取
    NL_CMS_DB_HOST=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "cms.url_1")
    echo "NL_CMS_DB_HOST=${NL_CMS_DB_HOST}"
    
    NL_CMS_DB_USER=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "cms.user_1")
    echo "NL_CMS_DB_USER=${NL_CMS_DB_USER}" 
    
    NL_CMS_DB_PASS=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "cms.passwd_1")
    # 去除密码前后空格
    NL_CMS_DB_PASS=$(trim "${NL_CMS_DB_PASS}")
    echo "NL_CMS_DB_PASS=${NL_CMS_DB_PASS}"
    
    NL_CMS_DB_NAME=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "cms.dbname_1")
    echo "NL_CMS_DB_NAME=${NL_CMS_DB_NAME}" 
    
    NL_CMS_SP_ID=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "cms.nl_sp_id_1")
    echo "NL_CMS_SP_ID=${NL_CMS_SP_ID}" 
    
    NL_CMS_PLATFORM_ID=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "cms.nl_platform_id_1")
    echo "NL_CMS_PLATFORM_ID=${NL_CMS_PLATFORM_ID}" 
    
    NL_AAA_DB_HOST=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "aaa.url_1")
    echo "NL_AAA_DB_HOST=${NL_AAA_DB_HOST}" 
    
    NL_AAA_DB_USER=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "aaa.user_1")
    echo "NL_AAA_DB_USER=${NL_AAA_DB_USER}" 
    
    NL_AAA_DB_PASS=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "aaa.passwd_1")
    echo "NL_AAA_DB_PASS=${NL_AAA_DB_PASS}" 
    
    NL_AAA_DB_NAME=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "aaa.dbname_1")
    echo "NL_AAA_DB_NAME=${NL_AAA_DB_NAME}" 
    
    HADOOP_FTP_HOST=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "ftp.host")
    echo "HADOOP_FTP_HOST=${HADOOP_FTP_HOST}" 
    
    HADOOP_FTP_USER=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "ftp.user")
    echo "HADOOP_FTP_USER=${HADOOP_FTP_USER}" 
    
    HADOOP_FTP_PWD=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "ftp.passwd")
    echo "HADOOP_FTP_PWD=${HADOOP_FTP_PWD}" 
    
    HADOOP_FTP_DIRECTORY=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "ftp.directory")
    echo "HADOOP_FTP_DIRECTORY=${HADOOP_FTP_DIRECTORY}" 
    
    NN_REDIS_HOST=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "redis.url")
    echo "NN_REDIS_HOST=${NN_REDIS_HOST}" 
    
    NN_REDIS_PORT=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "redis.port")
    echo "NN_REDIS_PORT=${NN_REDIS_PORT}" 
    
    NN_REDIS_PASSWD=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "redis.passwd")
    echo "NN_REDIS_PASSWD=${NN_REDIS_PASSWD}" 
    
    KAFKA_HOST=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "kafka.KAFKA_HOST")
    echo "KAFKA_HOST=${KAFKA_HOST}" 
    
    KAFKA_HOSTNAMES=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "kafka.KAFKA_HOSTNAMES")
    echo "KAFKA_HOSTNAMES=${KAFKA_HOSTNAMES}" 
    
    NL_SP_ID=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "nl_sp_id_1")
    echo "NL_SP_ID=${NL_SP_ID}" 
    
    HIVE_PLATFORM_ID=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "hive.platform_id")
    echo "HIVE_PLATFORM_ID=${HIVE_PLATFORM_ID}" 
    
    ES_HOST=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "es.host")
    echo "ES_HOST=${ES_HOST}" 
    
    ES_TCP_PORT=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "es.tcp.port")
    echo "ES_TCP_PORT=${ES_TCP_PORT}" 
    
    ES_HTTP_PORT=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "es.http.port")
    echo "ES_HTTP_PORT=${ES_HTTP_PORT}" 
    # ES TCP/HTTP主机地址处理
    isContain "${ES_HOST}" ","
    if [ $? -ne 0 ]; then
        ES_TCP_HOST=${ES_HOST}:${ES_TCP_PORT}
        ES_HTTP_HOST=${ES_HOST}:${ES_HTTP_PORT}
    else
        array=(${ES_HOST//,/ })
        for var in ${array[@]}
        do
            ES_TCP_HOST="${ES_TCP_HOST},${var}:${ES_TCP_PORT}"
            ES_HTTP_HOST="${ES_HTTP_HOST},${var}:${ES_HTTP_PORT}"
        done
    fi
    # 删除多余的逗号
    isStartWith ${ES_TCP_HOST} ","
    [[ $? -eq 0 ]] && ES_TCP_HOST=${ES_TCP_HOST:1} 
    # 删除多余的逗号
    isStartWith ${ES_HTTP_HOST} ","
    [[ $? -eq 0 ]] && ES_HTTP_HOST=${ES_HTTP_HOST:1} 
    
    
    ES_CLUSTER_NAME=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "es.cluster.name")
    echo "ES_CLUSTER_NAME=${ES_CLUSTER_NAME}" 
    
    NL_DB_HOST=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "mysql.NL_DB_HOST")
    echo "NL_DB_HOST=${NL_DB_HOST}" 
    
    NL_DB_USER=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "mysql.NL_DB_USER")
    echo "NL_DB_USER=${NL_DB_USER}" 
    
    NL_DB_PASS=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "mysql.NL_DB_PASS")
    echo "NL_DB_PASS=${NL_DB_PASS}" 
    
    NEO4J_URL=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "bdp.neo4j.url")
    echo "NEO4J_URL=${NEO4J_URL}" 
    
    DEFAULT_PLATFORM_ID=$(readIniFile ${DEPLOY_FILE_PATH} ${SDK_WS_NAME} "default.platform_id")
    [[ -z "${DEFAULT_PLATFORM_ID}" ]] && DEFAULT_PLATFORM_ID="default"
    echo "DEFAULT_PLATFORM_ID=${DEFAULT_PLATFORM_ID}" 
    
    KYLIN_URL=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "bdp.kylin.url")
    # 判断是否包含驱动信息
    isContain ${KYLIN_URL} "jdbc:kylin"
    if [ $? -ne 0 ]; then
        isContain ${KYLIN_URL} ":"
        if [ $? -ne 0 ]; then
            KYLIN_URL="jdbc:kylin://""${KYLIN_URL}"":7070""/${DEFAULT_PLATFORM_ID}"
        else
            KYLIN_URL="jdbc:kylin://""${KYLIN_URL}""/${DEFAULT_PLATFORM_ID}"
        fi
    fi
    echo "KYLIN_URL=${KYLIN_URL}" 
    
    KYLIN_USER=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "bdp.kylin.user")
    echo "KYLIN_USER=${KYLIN_USER}" 
    
    KYLIN_PASSWORD=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "bdp.kylin.password")  
    echo "KYLIN_PASSWORD=${KYLIN_PASSWORD}" 
    
    ZOOKEEPER_HOST=$(readIniFile ${DEPLOY_FILE_PATH} ${COMMON_SECTION} "zookeeper.kafka_zookeeper")  
    echo "ZOOKEEPER_HOST=${ZOOKEEPER_HOST}" 
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        readComponentParams
# createTime  :        2018-08-23
# description :        组件部署参数读取
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function readComponentParams()
{
    printMessageLog INFO "readComponentParams ${REPORTER_SYSTEM_NAME} starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}

    dos2unix ${DEPLOY_FILE_PATH}    

    # 报表平台组件参数获取
    NL_WEBSERVICE=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "NL_WEBSERVICE")
    # 判断是否包含驱动信息
    isStartWith ${NL_WEBSERVICE} "http"
    if [ $? -ne 0 ]; then
        isContain ${NL_WEBSERVICE} ":"
        if [ $? -ne 0 ]; then
            NL_WEBSERVICE="http://""${NL_WEBSERVICE}"":8082/apps/""${VERSION_NUMBER}""/"
        else
            NL_WEBSERVICE="http://""${NL_WEBSERVICE}""/apps/""${VERSION_NUMBER}""/"
        fi
    fi
    echo "NL_WEBSERVICE=${NL_WEBSERVICE}"
    
    # 个性化推荐老接口
    NL_RECOMMEND_SERVICE=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "NL_RECOMMEND_SERVICE")
    # 判断是否包含驱动信息
    isStartWith ${NL_RECOMMEND_SERVICE} "http"
    if [ $? -ne 0 ]; then
        isContain ${NL_RECOMMEND_SERVICE} ":"
        if [ $? -ne 0 ]; then
            NL_RECOMMEND_SERVICE="http://""${NL_RECOMMEND_SERVICE}"":8082/apps/${VERSION_NUMBER}/query/?action=get_recommend_content"
        else
            NL_RECOMMEND_SERVICE="http://""${NL_RECOMMEND_SERVICE}""/apps/${VERSION_NUMBER}/query/?action=get_recommend_content"
        fi
    fi
    echo "NL_RECOMMEND_SERVICE=${NL_RECOMMEND_SERVICE}"
    
    # 个性化推荐新接口
    NL_NEW_RECOMMEND_SERVICE_ALI=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "NL_NEW_RECOMMEND_SERVICE_ALI")
    # 判断是否包含驱动信息
    isStartWith ${NL_NEW_RECOMMEND_SERVICE_ALI} "http"
    if [ $? -ne 0 ]; then
        isContain ${NL_NEW_RECOMMEND_SERVICE_ALI} ":"
        if [ $? -ne 0 ]; then
            NL_NEW_RECOMMEND_SERVICE_ALI="http://""${NL_NEW_RECOMMEND_SERVICE_ALI}"":18083/apps/kpi/query/recommend"
        else
            NL_NEW_RECOMMEND_SERVICE_ALI="http://""${NL_NEW_RECOMMEND_SERVICE_ALI}""/apps/kpi/query/recommend"
        fi
    fi
    echo "NL_NEW_RECOMMEND_SERVICE_ALI=${NL_NEW_RECOMMEND_SERVICE_ALI}"
    
    NL_DOWNLOAD_WEBSERVICE=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "NL_DOWNLOAD_WEBSERVICE")
    # 判断是否包含驱动信息
    isStartWith ${NL_DOWNLOAD_WEBSERVICE} "http"
    if [ $? -ne 0 ]; then
        isContain ${NL_DOWNLOAD_WEBSERVICE} ":"
        if [ $? -ne 0 ]; then
            NL_DOWNLOAD_WEBSERVICE="http://""${NL_DOWNLOAD_WEBSERVICE}"":8082/apps/""${VERSION_NUMBER}""/"
        else
            NL_DOWNLOAD_WEBSERVICE="http://""${NL_DOWNLOAD_WEBSERVICE}""/apps/""${VERSION_NUMBER}""/"
        fi
    fi
    echo "NL_DOWNLOAD_WEBSERVICE=${NL_DOWNLOAD_WEBSERVICE}"
    
    NN_BRD_URL=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "NN_BRD_URL")
    # 判断是否包含驱动信息
    isStartWith ${NN_BRD_URL} "http"
    if [ $? -ne 0 ]; then
        isContain ${NN_BRD_URL} ":"
        if [ $? -ne 0 ]; then
            NN_BRD_URL="http://""${NN_BRD_URL}"":8090"
        else
            NN_BRD_URL="http://""${NN_BRD_URL}"
        fi
    fi
    echo "NN_BRD_URL=${NN_BRD_URL}"
    
    SYS_LOGINID=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "SYS_LOGINID")
    echo "SYS_LOGINID=${SYS_LOGINID}"
    
    SYS_LOGINPWD=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "SYS_LOGINPWD")
    echo "SYS_LOGINPWD=${SYS_LOGINPWD}"
    
    NL_DB_HOST=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "mysql.NL_DB_HOST")
    echo "NL_DB_HOST=${NL_DB_HOST}"
    
    NL_DB_USER=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "mysql.NL_DB_USER")
    echo "NL_DB_USER=${NL_DB_USER}"
    
    NL_DB_PASS=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "mysql.NL_DB_PASS")
    echo "NL_DB_PASS=${NL_DB_PASS}"
    
    NL_DB_NAME=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "mysql.NL_DB_NAME")
    echo "NL_DB_NAME=${NL_DB_NAME}"
    
    MAP_NAME=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "map.MAP_NAME")
    echo "MAP_NAME=${MAP_NAME}"
    
    MAP_CODE=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "map.MAP_CODE")
    echo "MAP_CODE=${MAP_CODE}"
    
    IF_IP_2_LATITUDE=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "map.ip_2_latitude")
    if [ -z "${IF_IP_2_LATITUDE}" ]; then
        IF_IP_2_LATITUDE="false"
    fi
    echo "IF_IP_2_LATITUDE=${IF_IP_2_LATITUDE}"
    
    AREA_CODE_CHANGE_RULE=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "region.area_code_change_rule")
    if [ -z "${AREA_CODE_CHANGE_RULE}" ]; then
        AREA_CODE_CHANGE_RULE=0
    fi
    echo "AREA_CODE_CHANGE_RULE=${AREA_CODE_CHANGE_RULE}"
    
    IS_SPLICE_SP_ID=$(readIniFile ${DEPLOY_FILE_PATH} ${REPORTER_SYSTEM_NAME} "error.is_splice_sp_id")
    if [ -z "${IS_SPLICE_SP_ID}" ]; then
        IS_SPLICE_SP_ID="false"
    fi
    echo "IS_SPLICE_SP_ID=${IS_SPLICE_SP_ID}"
    
    # 接口服务组件参数获取
    GRAPHX_URL=$(readIniFile ${DEPLOY_FILE_PATH} ${SDK_WS_NAME} "graphxUrl")
    echo "GRAPHX_URL=${GRAPHX_URL}"
    PRESTO_URL=$(readIniFile ${DEPLOY_FILE_PATH} ${SDK_WS_NAME} "presto.url")
    # 判断是否包含驱动信息
    isStartWith ${PRESTO_URL} "jdbc"
    if [ $? -ne 0 ]; then
        isContain ${PRESTO_URL} ":"
        if [ $? -ne 0 ]; then
            PRESTO_URL="jdbc:presto://""${PRESTO_URL}"":16060/hive/""${HIVE_PLATFORM_ID}"
        else
            PRESTO_URL="jdbc:presto://""${PRESTO_URL}/hive/""${HIVE_PLATFORM_ID}"
        fi
    fi
    echo "PRESTO_URL=${PRESTO_URL}"
    PRESTO_USER=$(readIniFile ${DEPLOY_FILE_PATH} ${SDK_WS_NAME} "presto.user")
    echo "PRESTO_USER=${PRESTO_USER}"
    # @TODO，presto无密码，不需要配置
    PRESTO_PASSWD=$(readIniFile ${DEPLOY_FILE_PATH} ${SDK_WS_NAME} "presto.pwd")
    echo "PRESTO_PASSWD=${PRESTO_PASSWD}"
    
    # 数据模型服务组件参数获取
    BW_MYQL_DB_HOST=$(readIniFile ${DEPLOY_FILE_PATH} ${DATA_MODEL_SERVICE_NAME} "mysql.bluewhale_host")
    echo "BW_MYQL_DB_HOST=${BW_MYQL_DB_HOST}"
    BW_MYQL_DB_USER=$(readIniFile ${DEPLOY_FILE_PATH} ${DATA_MODEL_SERVICE_NAME} "mysql.bluewhale_username")
    echo "BW_MYQL_DB_USER=${BW_MYQL_DB_USER}"
    BW_MYQL_DB_PASSWD=$(readIniFile ${DEPLOY_FILE_PATH} ${DATA_MODEL_SERVICE_NAME} "mysql.bluewhale_password")
    echo "BW_MYQL_DB_PASSWD=${BW_MYQL_DB_PASSWD}"
    BW_MYQL_DB_DBNAME=$(readIniFile ${DEPLOY_FILE_PATH} ${DATA_MODEL_SERVICE_NAME} "mysql.bluewhale_databasename")   
    echo "BW_MYQL_DB_DBNAME=${BW_MYQL_DB_DBNAME}"
    CLUSTER_MYQL_DB_HOST=$(readIniFile ${DEPLOY_FILE_PATH} ${DATA_MODEL_SERVICE_NAME} "mysql.cluster_host")
    echo "CLUSTER_MYQL_DB_HOST=${CLUSTER_MYQL_DB_HOST}"
    CLUSTER_MYQL_DB_USER=$(readIniFile ${DEPLOY_FILE_PATH} ${DATA_MODEL_SERVICE_NAME} "mysql.cluster_username")
    echo "CLUSTER_MYQL_DB_USER=${CLUSTER_MYQL_DB_USER}"
    CLUSTER_MYQL_DB_PASSWD=$(readIniFile ${DEPLOY_FILE_PATH} ${DATA_MODEL_SERVICE_NAME} "mysql.cluster_password")
    echo "CLUSTER_MYQL_DB_PASSWD=${CLUSTER_MYQL_DB_PASSWD}"
    CLUSTER_MYQL_DB_DBNAME=$(readIniFile ${DEPLOY_FILE_PATH} ${DATA_MODEL_SERVICE_NAME} "mysql.cluster_databasename")   
    echo "CLUSTER_MYQL_DB_DBNAME=${CLUSTER_MYQL_DB_DBNAME}"
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        readUpgradeParams
# createTime  :        2018-08-23
# description :        组件部署参数读取
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function readUpgradeParams()
{
    printMessageLog INFO "readUpgradeParams starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    local componentName=$1
    local configFilePath=$2
    printMessageLog DEBUG "componentName=${componentName}, configFilePath=${configFilePath}." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    if [ ${componentName} = ${REPORTER_SYSTEM_NAME} ]; then
        readRSPUpgradeParams ${configFilePath}
        [ $? -ne 0 ] && return 1
    elif [ ${componentName} = ${SDK_WS_NAME} ]; then
        readSDKWSUpgradeParams ${configFilePath}
        [ $? -ne 0 ] && return 1
    elif [ ${componentName} = ${VBS_WS_NAME} ]; then
        return 0
    elif [ ${componentName} = ${CREATE_GX_NAME} ]; then
        return 0
    elif [ ${componentName} = ${USER_PROFILE_NAME} ]; then
        return 0
    elif [ ${componentName} = ${WS_OUTFILE_NAME} ]; then
        return 0
    elif [ ${componentName} = ${DATA_INTEGRATION_NAME} ]; then
        return 0
    elif [ ${componentName} = ${REALTIME_ENGINE_NAME} ]; then
        return 0
    elif [ ${componentName} = ${LOGMGR_NAME} ]; then
        return 0
    elif [ ${componentName} = ${DATA_MODEL_SERVICE_NAME} ]; then
        readDMSUpgadeParams  ${configFilePath}
        [ $? -ne 0 ] && return 1
    elif [ ${componentName} = ${META_LOAD_NAME} ]; then
        return 0
    elif [ ${componentName} = ${STREAMING_LOAD_NAME} ]; then
        return 0 
    else
        printMessageLog ERROR "unknow compenent name is, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi    
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        readRSPUpgradeParams
# createTime  :        2018-08-23
# description :        获取报表平台部署参数
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function readRSPUpgradeParams()
{
    printMessageLog INFO "readRSPUpgradeParams starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    local configFilePath=$1
    # 路径校验
    checkFilePath ${configFilePath} 
    
    NL_CMS_DB_HOST=$(readPHPConfig "NL_CMS_DB_HOST_1" ${configFilePath})
    echo "NL_CMS_DB_HOST=${NL_CMS_DB_HOST}"
    NL_CMS_DB_USER=$(readPHPConfig "NL_CMS_DB_USER_1" ${configFilePath})
    echo "NL_CMS_DB_USER=${NL_CMS_DB_USER}"
    NL_CMS_DB_PASS=$(readPHPConfig "NL_CMS_DB_PASS_1" ${configFilePath})
    echo "NL_CMS_DB_PASS=${NL_CMS_DB_PASS}"
    NL_CMS_DB_NAME=$(readPHPConfig "NL_CMS_DB_NAME_1" ${configFilePath})
    echo "NL_CMS_DB_NAME=${NL_CMS_DB_NAME}"
    NL_AAA_DB_HOST=$(readPHPConfig "NL_AAA_DB_HOST_1" ${configFilePath})
    echo "NL_AAA_DB_HOST=${NL_AAA_DB_HOST}"
    NL_AAA_DB_USER=$(readPHPConfig "NL_AAA_DB_USER_1" ${configFilePath})
    echo "NL_AAA_DB_USER=${NL_AAA_DB_USER}"
    NL_AAA_DB_PASS=$(readPHPConfig "NL_AAA_DB_PASS_1" ${configFilePath})
    echo "NL_AAA_DB_PASS=${NL_AAA_DB_PASS}"
    NL_AAA_DB_NAME=$(readPHPConfig "NL_AAA_DB_NAME_1" ${configFilePath})
    echo "NL_AAA_DB_NAME=${NL_AAA_DB_NAME}"
    HADOOP_FTP_HOST=$(readPHPConfig "HADOOP_FTP_HOST" ${configFilePath})
    echo "HADOOP_FTP_HOST=${HADOOP_FTP_HOST}"
    HADOOP_FTP_USER=$(readPHPConfig "HADOOP_FTP_USER" ${configFilePath})
    echo "HADOOP_FTP_USER=${HADOOP_FTP_USER}"
    HADOOP_FTP_PWD=$(readPHPConfig "HADOOP_FTP_PWD" ${configFilePath})
    echo "HADOOP_FTP_PWD=${HADOOP_FTP_PWD}"
    HADOOP_FTP_DIRECTORY=$(readPHPConfig "HADOOP_FTP_DIRECTORY" ${configFilePath})
    echo "HADOOP_FTP_DIRECTORY=${HADOOP_FTP_DIRECTORY}"
    NN_REDIS_HOST=$(readPHPConfig "NN_REDIS_HOST" ${configFilePath})
    echo "NN_REDIS_HOST=${NN_REDIS_HOST}"
    NN_REDIS_PORT=$(readPHPConfig "NN_REDIS_PORT" ${configFilePath})
    echo "NN_REDIS_PORT=${NN_REDIS_PORT}"
    KAFKA_HOST=$(readPHPConfig "KAFKA_HOST" ${configFilePath})
    echo "KAFKA_HOST=${KAFKA_HOST}"
    NL_SP_ID=$(readPHPConfig "NL_SP_ID_1" ${configFilePath})
    echo "NL_SP_ID=${NL_SP_ID}"
    NL_CMS_PLATFORM_ID=$(readPHPConfig "NL_PLATFORM_ID_1" ${configFilePath})
    echo "NL_CMS_PLATFORM_ID=${NL_CMS_PLATFORM_ID}"
    
    NL_WEBSERVICE=$(readPHPConfig "NL_WEBSERVICE" ${configFilePath})
    echo "NL_WEBSERVICE=${NL_WEBSERVICE}"
    NL_RECOMMEND_SERVICE=$(readPHPConfig "NL_RECOMMEND_SERVICE" ${configFilePath})
    echo "NL_RECOMMEND_SERVICE=${NL_RECOMMEND_SERVICE}"
    NL_NEW_RECOMMEND_SERVICE_ALI=$(readPHPConfig "NL_NEW_RECOMMEND_SERVICE_ALI" ${configFilePath})
    echo "NL_NEW_RECOMMEND_SERVICE_ALI=${NL_NEW_RECOMMEND_SERVICE_ALI}"
    NL_DOWNLOAD_WEBSERVICE=$(readPHPConfig "NL_DOWNLOAD_WEBSERVICE" ${configFilePath})
    echo "NL_DOWNLOAD_WEBSERVICE=${NL_DOWNLOAD_WEBSERVICE}"
    SYS_LOGINID=$(readPHPConfig "SYS_LOGINID" ${configFilePath})
    echo "SYS_LOGINID=${SYS_LOGINID}"
    SYS_LOGINPWD=$(readPHPConfig "SYS_LOGINPWD" ${configFilePath})
    echo "SYS_LOGINPWD=${SYS_LOGINPWD}"
    NL_DB_HOST=$(readPHPConfig "NL_DB_HOST" ${configFilePath})
    echo "NL_DB_HOST=${NL_DB_HOST}"
    NL_DB_USER=$(readPHPConfig "NL_DB_USER" ${configFilePath})
    echo "NL_DB_USER=${NL_DB_USER}"
    NL_DB_PASS=$(readPHPConfig "NL_DB_PASS" ${configFilePath})
    echo "NL_DB_PASS=${NL_DB_PASS}"
    NL_DB_NAME=$(readPHPConfig "NL_DB_NAME" ${configFilePath})
    echo "NL_DB_NAME=${NL_DB_NAME}"
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        readSDKWSUpgradeParams
# createTime  :        2018-08-23
# description :        接口查询模块升级原始参数获取
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function readSDKWSUpgradeParams()
{
    printMessageLog WARN "readSDKWSUpgradeParams starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    local configFilePath=$1    
    # 路径校验
    checkFilePath ${configFilePath} 
    
    # 公共参数获取
    ES_HOST=$(readConfig "es.host" ${configFilePath})
    echo "ES_HOST=${ES_HOST}"
    ES_TCP_PORT=$(readConfig "es.tcp.port" ${configFilePath})
    echo "ES_TCP_PORT=${ES_TCP_PORT}"
    ES_CLUSTER_NAME=$(readConfig "es.cluster.name" ${configFilePath})
    echo "ES_CLUSTER_NAME=${ES_CLUSTER_NAME}"
    NN_REDIS_HOST=$(readConfig "realtimeRedis" ${configFilePath})
    echo "NN_REDIS_HOST=${NN_REDIS_HOST}"
    NN_REDIS_PASSWD=$(readConfig "realtimeRedisPwd" ${configFilePath})
    echo "NN_REDIS_PASSWD=${NN_REDIS_PASSWD}"
    NEO4J_URL==$(readConfig "bdp.neo4j.url" ${configFilePath})
    echo "NEO4J_URL=${NEO4J_URL}" 
    KYLIN_URL==$(readConfig "bdp.kylin.url" ${configFilePath})
    echo "KYLIN_URL=${KYLIN_URL}" 
    KYLIN_USER==$(readConfig "bdp.kylin.user" ${configFilePath})
    echo "KYLIN_USER=${KYLIN_USER}" 
    KYLIN_PASSWORD==$(readConfig "bdp.kylin.password" ${configFilePath})  
    echo "KYLIN_PASSWORD=${KYLIN_PASSWORD}" 

    # 组件参数获取
    GRAPHX_URL=$(readConfig "graphxUrl" ${configFilePath})
    echo "GRAPHX_URL=${GRAPHX_URL}"
    PRESTO_URL=$(readConfig "presto.url" ${configFilePath})
    echo "PRESTO_URL=${PRESTO_URL}"
    PRESTO_USER=$(readConfig "presto.user" ${configFilePath})
    echo "PRESTO_USER=${PRESTO_USER}"
    PRESTO_PASSWD=$(readConfig "presto.pwd" ${configFilePath})
    echo "PRESTO_PASSWD=${PRESTO_PASSWD}"
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        readDMSUpgadeParams
# createTime  :        2018-08-23
# description :        数据模型服务组件升级参数读取
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function readDMSUpgadeParams()
{
    printMessageLog INFO "readSDKWSUpgradeParams starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    local configFilePath=$1  
    # 路径校验
    checkFilePath ${configFilePath} 
    
    NL_DB_HOST=$(readIniFile ${configFilePath} ${REPORTER_SYSTEM_NAME} "mysql.NL_DB_HOST")
    echo "NL_DB_HOST=${NL_DB_HOST}"
    NL_DB_USER=$(readIniFile ${configFilePath} ${REPORTER_SYSTEM_NAME} "mysql.NL_DB_USER")
    echo "NL_DB_USER=${NL_DB_USER}"
    NL_DB_PASS=$(readIniFile ${configFilePath} ${REPORTER_SYSTEM_NAME} "mysql.NL_DB_PASS")
    echo "NL_DB_PASS=${NL_DB_PASS}"
    BW_MYQL_DB_HOST=$(readIniFile ${configFilePath} ${DATA_MODEL_SERVICE_NAME} "mysql.bluewhale_host")
    echo "BW_MYQL_DB_HOST=${BW_MYQL_DB_HOST}"
    BW_MYQL_DB_USER=$(readIniFile ${configFilePath} ${DATA_MODEL_SERVICE_NAME} "mysql.bluewhale_username")
    echo "BW_MYQL_DB_USER=${BW_MYQL_DB_USER}"
    BW_MYQL_DB_PASSWD=$(readIniFile ${configFilePath} ${DATA_MODEL_SERVICE_NAME} "mysql.bluewhale_password")
    echo "BW_MYQL_DB_PASSWD=${BW_MYQL_DB_PASSWD}"
    BW_MYQL_DB_DBNAME=$(readIniFile ${configFilePath} ${DATA_MODEL_SERVICE_NAME} "mysql.bluewhale_databasename")
    echo "BW_MYQL_DB_DBNAME=${BW_MYQL_DB_DBNAME}"
    HIVE_PLATFORM_ID=$(readIniFile ${configFilePath} ${COMMON_SECTION} "hive.platform_id_1")
    echo "HIVE_PLATFORM_ID=${HIVE_PLATFORM_ID}"
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        checkFilePath
# createTime  :        2018-08-29
# description :        配置文件路径校验
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function checkFilePath()
{
    local configFilePath=$1    
    if [ -z ${configFilePath} ]; then
        printMessageLog ERROR "config file path is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        exit 1
    elif [ ! -f ${configFilePath} ]; then 
        printMessageLog ERROR "${configFilePath} no such file." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        exit 1
    fi
    
    dos2unix ${configFilePath} 
}

# ----------------------------------------------------------------------
# FunctionName:		compareVersions
# createTime  :		2018-12-24
# description :		比较两个版本号
# author      :		wenfeng.duan
# return      :     0:相等, 1:第一个版本小, 2:第二个版本小
# ----------------------------------------------------------------------
function compareVersions()
{
    local v1=( $(echo "$1" | tr '.' ' ') )
    local v2=( $(echo "$2" | tr '.' ' ') )
    local len="$(max "${#v1[*]}" "${#v2[*]}")"
    for ((i=0; i<len; i++))
    do
        [[ "${v1[i]:-0}" -lt "${v2[i]:-0}" ]] && return 1
        [[ "${v1[i]:-0}" -gt "${v2[i]:-0}" ]] && return 2
    done
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		min
# createTime  :		2018-12-24
# description :		返回两个数的最小值
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function min()
{
    local m="$1"
    for n in "$@"
    do
        [[ "$n" -lt "$m" ]] && m="$n"
    done
    echo "$m"
}

# ----------------------------------------------------------------------
# FunctionName:		max
# createTime  :		2018-12-24
# description :		返回两个数的最大值
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function max()
{
    local m="$1"
    for n in "$@"
    do
        [[ "$n" -gt "$m" ]] && m="$n"
    done
    echo "$m"
}

# ----------------------------------------------------------------------
# FunctionName:		readSectionList
# createTime  :		2019-03-11
# description :		读取ini文件中某个section的所有值
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function readSectionList()
{
    if [ $# -lt 2 ]; then
        printMessageLog ERROR "parameter is invalid, at least 2 parameters, which contain file path and section." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        exit 1
    fi
    local iniFilePath=$1
    local section=$2
    
    if [ ! -f ${iniFilePath} ]; then
        printMessageLog ERROR "File ${iniFilePath} is not exist." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        exit 1
    fi

    printMessageLog INFO "sed -n \"/\[${section}\]/,/\[.*\]/p\" ${iniFilePath} | grep -v \"\[.*\]\" | awk -F'=' '{print $1}' | sed 'N;$!P;D' | sed '$d'" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    local valueList=$(sed -n "/\[${section}\]/,/\[.*\]/p" ${iniFilePath} | grep -v "\[.*\]" | awk -F'=' '{print $1}' | sed 'N;$!P;D' | sed '$d')

    echo "${valueList}"
}

# ----------------------------------------------------------------------
# FunctionName:		trim
# createTime  :		2019-03-13
# description :		去除字符串前后空格
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function trim()
{
    local string=$1
    
    if [ -z "${string}" ]; then
        echo ""
    else
        echo "${string}" | sed -e 's/^[ ]*//g' | sed -e 's/[ ]*$//g'
    fi
}

# ----------------------------------------------------------------------
# FunctionName:		trimBefore
# createTime  :		2019-03-13
# description :		去除字符串前空格
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function trimBefore()
{
    local string=$1
    
    if [ -z "${string}" ]; then
        echo ""
    else
        echo "${string}" | sed -e 's/^[ ]*//g'
    fi
}

# ----------------------------------------------------------------------
# FunctionName:		trimAfter
# createTime  :		2019-03-13
# description :		去除字符串后空格
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function trimAfter()
{
    local string=$1
    
    if [ -z "${string}" ]; then
        echo ""
    else
        echo "${string}" | sed -e 's/[ ]*$//g'
    fi
}

# ----------------------------------------------------------------------
# FunctionName:		readInput
# createTime  :		2019-03-22
# description :		接收命令行输入参数并校验
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function readInput()
{
    read -p "请输入是否继续，Y[yes] or N[no]: " input

    if [ x"yes" == x"${input}" -o x"Y" == x"${input}" ]; then
        printMessageLog ERROR "参入参数为：${input}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 0
    elif [ x"no" == x"${input}" -o x"N" == x"${input}" ]; then
        printMessageLog ERROR "参入参数为：${input}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    else
        echo "输入参数有误"
        return 1
    fi
}

# ----------------------------------------------------------------------
# FunctionName:		backup_directory
# createTime  :		2019-03-25
# description :		目录备份
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function backup_directory()
{
    local path=$1
    local serviceName=$2
    
    if [ ! -d "${path}/${serviceName}" ]; then
        printMessageLog INFO "${path}/${serviceName}: No such file or directory, no need to backup." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 0
    fi
    
    # 获取当前时间
    local now=$(getCurrentTime)
    
    cp -a -r ${path}/${serviceName} ${BACKUP_ROOT_PATH}/${serviceName}_${now}
    [[ $? -ne 0 ]] && return 1
    
    cd ${BACKUP_ROOT_PATH}
    tar -czvf ${serviceName}_${now}.tar.gz ${BACKUP_ROOT_PATH}/${serviceName}_${now}
    [[ $? -ne 0 ]] && return 1
    cd ${CURRENT_PATH}
    
    return 0
}