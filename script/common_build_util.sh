#!bin/bash

CLASS_NAME=$(basename $0)
CUR_PATH=$(cd "$(dirname "$0")";pwd)

# 日志路径
LOG_PATH=""
LOG_FILE_NAME=""

# 代码目录
readonly SVN_CODE_PATH=/opt/svn
readonly SVN_ROOT_PATH=${CUR_PATH}/../../..

# 组件编译目录
readonly TARGET_PATH=${CUR_PATH}/../../target
COMPONENT_BUILD_PATH=""

# SVN账号密码
readonly SVN_USERNAME=wenfeng.duan
readonly SVN_PASSWORD=dwf20180620

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
# FunctionName:        initLog
# createTime  :        2018-08-21
# description :        初始化日志文件
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function initLog()
{
    componentName=$1

    if [ -z ${componentName} ]; then
        echo "component name is null, invalid."
    fi

    LOG_PATH=${TARGET_PATH}/logs
    LOG_FILE_NAME=${componentName}_build.log

    if [ ! -d ${LOG_PATH} ]; then
        mkdir -p ${LOG_PATH}
    fi

    if [ ! -f ${LOG_PATH}/${LOG_FILE_NAME} ]; then
        touch ${LOG_PATH}/${LOG_FILE_NAME}
    else
        cat /dev/null > ${LOG_PATH}/${LOG_FILE_NAME}
    fi

    chmod 755 ${LOG_PATH}
    chmod 640 ${LOG_PATH}/${LOG_FILE_NAME}
}

# ----------------------------------------------------------------------
# FunctionName:        printMessageLog
# createTime  :        2018-08-21
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
    
    if [ -z ${lineNo} ]; then
        lineNo=$4
        funcName=" "
    fi

    local currentTime=`date "+%Y-%m-%d %H:%M:%S"`

    echo "[${logLevel}][${currentTime}][${className}|${funcName}|LINENO:${lineNo}][${message}]"
    echo "[${logLevel}][${currentTime}][${className}|${funcName}|LINENO:${lineNo}][${message}]" >> ${LOG_PATH}/${LOG_FILE_NAME}
}

# ----------------------------------------------------------------------
# FunctionName:        initTargetDirectory
# createTime  :        2018-08-21
# description :        初始化组件编译目录
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function initTargetDirectory()
{
    componentName=$1
    versionNumber=$2

    if [ -z ${componentName} ]; then
        printMessageLog ERROR "component name is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi

    # 获取微服务名称
    getMicroServiceName ${componentName}

    COMPONENT_BUILD_PATH=${TARGET_PATH}/${MICRO_SERVICE_NAME}/${componentName}_${versionNumber}

    if [ -d ${COMPONENT_BUILD_PATH} ]; then
        rm -rf ${COMPONENT_BUILD_PATH}
    fi

    mkdir -p ${COMPONENT_BUILD_PATH}
    chmod 755 ${COMPONENT_BUILD_PATH}
}

# ----------------------------------------------------------------------
# FunctionName:        checkoutSVNCode
# createTime  :        2018-08-21
# description :        更新svn代码
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function checkoutSVNCode()
{
    printMessageLog INFO "svn checkout https://svn.jetlive.net:8443/svn/rd/code/标准产品_大数据平台/trunk ${SVN_CODE_PATH}/ --username=${SVN_USERNAME} --password=${SVN_PASSWORD}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    svn checkout https://svn.jetlive.net:8443/svn/rd/code/标准产品_大数据平台/trunk ${SVN_CODE_PATH}/ --username=${SVN_USERNAME} --password=${SVN_PASSWORD} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1

    if [ $? -ne 0 ]; then
        return 1
    fi

    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        updateSVNCode
# createTime  :        2018-08-21
# description :        更新svn代码
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function updateSVNCode()
{
    printMessageLog INFO "svn update ${SVN_ROOT_PATH}/ --username=${SVN_USERNAME} --password=${SVN_PASSWORD} --accept theirs-full" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    svn update ${SVN_ROOT_PATH}/ --username=${SVN_USERNAME} --password=${SVN_PASSWORD}  --accept theirs-full >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1

    if [ $? -ne 0 ]; then
        return 1
    fi

    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        getSVNCommitID
# createTime  :        2018-08-21
# description :        获取最新的svn提交ID
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function getSVNCommitID()
{
    local localPath=$1
    local revision=""

    # 若传入代码路径为空，默认取代码根目录代码的最后提交svn号
    if [ -z "${localPath}" ]; then
        localPath=${SVN_ROOT_PATH}
    fi

    # 根据路径获取该路径下代码最后提交的svn版本号
    revision=`svn info ${localPath} --username=${SVN_USERNAME} --password=${SVN_PASSWORD} | grep "Last Changed Rev" | awk -F ": " '{print $2}'`

    echo ${revision}
}

# ----------------------------------------------------------------------
# FunctionName:        writeVersionFile
# createTime  :        2018-08-21
# description :        将版本号和commitid写入version文件
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function writeVersionFile()
{
    svn checkout https://svn.jetlive.net:8443/svn/rd/code/标准产品_大数据平台/trunk --username=wenfeng.duan --password=dwf20180620
}

# ----------------------------------------------------------------------
# FunctionName:        cleanMavenProject
# createTime  :        2018-08-21
# description :        Maven工程Clean
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function cleanMavenProject()
{
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        showProcessBar
# createTime  :        2018-08-22
# description :        进度条显示
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function showProcessBar()
{
    sleepTime=$1
    if [ -z ${sleepTime} ]; then
        sleepTime=1
    fi
    local i=0;
    local str=""
    local arr=("|" "/" "-" "\\")
    while [ $i -le 100 ]
    do
        let index=i%4
        let indexcolor=i%8
        let color=30+indexcolor
        printf "\e[0;$color;1m[%-100s][%d%%]%c\r" "$str" "$i" "${arr[$index]}"
        sleep ${sleepTime}
        let i++
        str+='='
    done
    printf "\n"
}

# ----------------------------------------------------------------------
# FunctionName:		modifyConfig
# createTime  :		2018-08-21
# description :		修改配置文件
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function modifyConfig()
{
    local key=$1
    local value=$2
    local configFile=$3
    printMessageLog DEBUG "configFile=${configFile}, key=${key}, value=${value}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}

    if [ ! -f ${configFile} ];then
        printMessageLog ERROR "${configFile} does not exist." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    local isExist=$(grep "^\s*${key}\s*=" "${configFile}")
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "get ${key} from ${configFile} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    elif [ -z "${isExist}" ]; then
        echo "${key}=${value}" >> "${configFile}"
    else
        sed -i "s#^\s*${key}\s*=.*#${key}=${value}#g" ${configFile}
    fi

    if [ $? -eq 0 ]; then
        printMessageLog INFO "update ${configFile} set ${key}=${value} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    else
        printMessageLog ERROR "update ${configFile} set ${key}=${value} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    fi
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
    local start=$2

    if [[ "${string}" =~ ${start}$ ]]; then
        return 0
    fi

    return 1
}

# ----------------------------------------------------------------------
# FunctionName:        isContain
# createTime  :        2018-08-22
# description :        判断字符串是否包含某个字符串
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function isContain()
{
    local string=$1
    local start=$2

    if [[ "${string}" =~ ${start} ]]; then
        return 0
    fi

    return 1
}

# ----------------------------------------------------------------------
# FunctionName:        buildMavenProject
# createTime  :        2018-08-21
# description :        Maven工程编译
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function buildMavenProject()
{
    return 0
}


