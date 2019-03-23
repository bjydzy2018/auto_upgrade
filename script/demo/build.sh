#!bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)
PARENT_PATH=$(cd "${CURRENT_PATH}/..";pwd)
source ${PARENT_PATH}/common_build_util.sh

# 组件源代码路径
COMPONENT_CODE_PATH=${SVN_ROOT_PATH}/reporter_system_v2

# 初始化日志
initLog ${REPORTER_SYSTEM_NAME}

VERSION_NUMBER=""

# ----------------------------------------------------------------------
# FunctionName:        main
# createTime  :        2018-08-21
# description :        主函数入口
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    # 获取版本号
    if [ $# -ge 1 ]; then
        local versionNumber=$1
        isStartWith ${versionNumber} "v"
        if [ $? -ne 0 ]; then
            VERSION_NUMBER="v"${versionNumber}
         else
            VERSION_NUMBER=${versionNumber}
        fi
        
        printMessageLog DEBUG "version number is ${VERSION_NUMBER}." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    else
        printMessageLog ERROR "version number is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    #  初始化组件打包目录
    initTargetDirectory ${REPORTER_SYSTEM_NAME} ${VERSION_NUMBER}

    # 更新SVN代码
    printMessageLog INFO "start update svn code ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    updateSVNCode
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "update svn code failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    printMessageLog INFO "end update svn code ." ${CLASS_NAME} ${FUNCNAME} ${LINENO}

    # 目录初始化
    createDirectory
    if [ $? -ne 0 ]; then
        return 1
    fi

    # maven工程编译
    buildMaven
    if [ $? -ne 0 ]; then
        return 1
    fi

    # 复制依赖包
    copyLibFile
    if [ $? -ne 0 ]; then
        return 1
    fi

    # 复制配置文件和其他文件
    copyConfigFile
    if [ $? -ne 0 ]; then
        return 1
    fi

    # 更新版本号
    updateVersion
    if [ $? -ne 0 ]; then
        return 1
    fi

    # 打包
    tarComponentPackage
    if [ $? -ne 0 ]; then
        return 1
    fi

    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        createDirectory
# createTime  :        2018-08-21
# description :        目录创建
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function createDirectory()
{
    printMessageLog DEBUG "start create component directory ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 创建om脚本目录
    if [ ! -d ${COMPONENT_BUILD_PATH}/script/ ]; then
        mkdir -p ${COMPONENT_BUILD_PATH}/script/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1

        if [ $? -ne 0 ]; then
            printMessageLog ERROR "create ${COMPONENT_BUILD_PATH}/script/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
    fi

    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        buildMaven
# createTime  :        2018-08-21
# description :        maven工程编译，并将Jar包复制到对应目录
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function buildMaven()
{
    printMessageLog DEBUG "start build maven project ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        copyLibFile
# createTime  :        2018-08-21
# description :        复制依赖包到对应目录
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function copyLibFile()
{
    printMessageLog DEBUG "start copy lib file ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        copyConfigFile
# createTime  :        2018-08-21
# description :        复制配置文件和其他文件到对应目录
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function copyConfigFile()
{
    printMessageLog DEBUG "start copy config files ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 代码路径复制
    rsync -a -r ${COMPONENT_CODE_PATH}/abtest_cms/ ${COMPONENT_BUILD_PATH}/abtest_cms/  --exclude=*.svn* >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${COMPONENT_CODE_PATH}/api/ ${COMPONENT_BUILD_PATH}/api --exclude=*.svn* >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${COMPONENT_CODE_PATH}/data/ ${COMPONENT_BUILD_PATH}/data/ --exclude=*.svn*  >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${COMPONENT_CODE_PATH}/mobile/ ${COMPONENT_BUILD_PATH}/mobile/ --exclude=*.svn*  >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${COMPONENT_CODE_PATH}/sync_plantform/ ${COMPONENT_BUILD_PATH}/sync_plantform/ --exclude=*.svn*  >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${COMPONENT_CODE_PATH}/tools/ ${COMPONENT_BUILD_PATH}/tools/ --exclude=*.svn*  >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${COMPONENT_CODE_PATH}/web/ ${COMPONENT_BUILD_PATH}/web/ --exclude=*.svn*  >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${COMPONENT_CODE_PATH}/index.php ${COMPONENT_BUILD_PATH}/index.php >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${COMPONENT_CODE_PATH}/list.txt ${COMPONENT_BUILD_PATH}/list.txt >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${COMPONENT_CODE_PATH}/nn_config.ini ${COMPONENT_BUILD_PATH}/nn_config.ini >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${COMPONENT_CODE_PATH}/nn_config.php ${COMPONENT_BUILD_PATH}/nn_config.php >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${COMPONENT_CODE_PATH}/readme.txt ${COMPONENT_BUILD_PATH}/readme.txt >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${COMPONENT_CODE_PATH}/version.php ${COMPONENT_BUILD_PATH}/version.php >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1

    # om文件复制
    rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/${REPORTER_SYSTEM_NAME}/*.sh ${COMPONENT_BUILD_PATH}/script/ --exclude=build.sh >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/common_dep_util.sh ${COMPONENT_BUILD_PATH}/script/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1

    # 部署配置文件复制
    rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/param.ini ${COMPONENT_BUILD_PATH}/script/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/default.ini ${COMPONENT_BUILD_PATH}/script/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
}

# --------------------------------------------------------------------------------------------------------------------------------------------
# FunctionName:        updateVersion
# createTime  :        2018-08-21
# description :        更新version文件，包含版本号和commitid，报表平台除外，暂时使用version.php，但需要更新版本号
# author      :        wenfeng.duan
# --------------------------------------------------------------------------------------------------------------------------------------------
function updateVersion()
{
    printMessageLog DEBUG "start update version ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    cd ${COMPONENT_BUILD_PATH}/
    sed -i "s#\s*PLANT_VERSION.*#PLANT_VERSION\", \"${VERSION_NUMBER}\");#g" version.php >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
}

# ----------------------------------------------------------------------
# FunctionName:        tarComponentPackage
# createTime  :        2018-08-21
# description :        将目录打成tar包
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function tarComponentPackage()
{
    printMessageLog DEBUG "start compressed component package ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    cd ${COMPONENT_BUILD_PATH}/..
    tar -czvf ${REPORTER_SYSTEM_NAME}_${VERSION_NUMBER}.tar.gz ${REPORTER_SYSTEM_NAME}_${VERSION_NUMBER} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    # 显示进度条
#    showProcessBar 2

    cd ${CURRENT_PATH}
}


main $*
if [ $? -ne 0 ]; then
    printMessageLog ERROR "build ${REPORTER_SYSTEM_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    exit 1
else
    printMessageLog INFO "build ${REPORTER_SYSTEM_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    exit 0
fi
