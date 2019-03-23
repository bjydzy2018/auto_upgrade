#!bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)
PARENT_PATH=$(cd "${CURRENT_PATH}/..";pwd)
source ${PARENT_PATH}/common_build_util.sh

# 组件源代码路径
COMPONENT_CODE_PATH=${SVN_ROOT_PATH}/analyse_system/sdkws/sdkws-modules
THIRD_CODE_PATH=${SVN_ROOT_PATH}/analyse_system/sdkws/third

MODULE_LIST=(getkpifile module-abtest module-ads module-analyze module-basicdata module-behaviorkpi module-cdnkpi module-contentkpi module-devicekpi module-logmonitorkpi module-personas module-qualitykpi module-realtimekpi module-recommend module-saleskpi module-swPost module-userkpi module-kylinkpi)

# 初始化日志
initLog ${SDK_WS_NAME}

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
        
        printMessageLog INFO "version number is ${VERSION_NUMBER}." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    else
        printMessageLog ERROR "version number is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    # 初始化组件打包目录
    initTargetDirectory ${SDK_WS_NAME} ${VERSION_NUMBER}

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
    printMessageLog WARN "start create component directory ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}

    if [ -d "${COMPONENT_BUILD_PATH}" ]; then
        if [ "${COMPONENT_BUILD_PATH}" =~ "${SDK_WS_NAME}" ]; then
            rm -rf ${COMPONENT_BUILD_PATH}
        fi
    fi

    # 创建om脚本目录
    printMessageLog INFO "create ${COMPONENT_BUILD_PATH}/script/ " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    mkdir -p ${COMPONENT_BUILD_PATH}/script/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create ${COMPONENT_BUILD_PATH}/script/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    # 创建module目录
    printMessageLog INFO "create ${COMPONENT_BUILD_PATH}/module/ " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    mkdir -p ${COMPONENT_BUILD_PATH}/module/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create ${COMPONENT_BUILD_PATH}/module/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    # 创建third目录
    printMessageLog INFO "create ${COMPONENT_BUILD_PATH}/third/ " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    mkdir -p ${COMPONENT_BUILD_PATH}/third/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create ${COMPONENT_BUILD_PATH}/third/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 创建third目录
    printMessageLog INFO "create ${COMPONENT_BUILD_PATH}/core/ " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    mkdir -p ${COMPONENT_BUILD_PATH}/core/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create ${COMPONENT_BUILD_PATH}/core/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    # 创建conf目录
    printMessageLog INFO "create ${COMPONENT_BUILD_PATH}/conf/indexValidation/ " ${CLASS_NAME} ${FUNCNAME} ${LINENO}
     mkdir -p ${COMPONENT_BUILD_PATH}/conf/indexValidation/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
     if [ $? -ne 0 ]; then
         printMessageLog ERROR "create ${COMPONENT_BUILD_PATH}/conf/indexValidation/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
         return 1
     fi
    
    printMessageLog WARN "end create component directory." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog WARN "start build maven project ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    local versionNumber=""

    isStartWith ${VERSION_NUMBER} "v"
    if [ $? -eq 0 ]; then
        versionNumber=$(echo ${VERSION_NUMBER:1})
    else
        versionNumber=${VERSION_NUMBER}
    fi

    cd ${COMPONENT_CODE_PATH}

    # 更新pom文件的版本号
    printMessageLog INFO "update pom.xml, set sdk.version=${versionNumber}  ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    modifyXMLConfig "sdk.version" "${versionNumber}" ${COMPONENT_CODE_PATH}/pom.xml
    if [ $? -ne 0 ]; then
        printMessageLog INFO "update sdk.version failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    # maven编译
    if [ -d ${COMPONENT_CODE_PATH}/target ]; then
        printMessageLog INFO "delete target directory  ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        rm -rf ${COMPONENT_CODE_PATH}/target >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    fi

    printMessageLog INFO "excute: mvn -U clean package -Dmaven.test.skip=true -Dmaven.test.failture.ignore=true  ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    mvn -U clean package -Dmaven.test.skip=true -Dmaven.test.failture.ignore=true
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "compilation ${SDK_WS_NAME} project failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    printMessageLog INFO "compilation ${SDK_WS_NAME} project successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}

    # 解压和复制文件
#    cd ${COMPONENT_CODE_PATH}/target
#    fileList=$(ls *.zip)
#
#    for file in ${fileList[@]}
#    do
#        printMessageLog INFO "unzip -o ${file}." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
#        unzip -o ${file} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
#    done

    # 复制jar包到部署包目录
    printMessageLog INFO "copy jar to the directory ${COMPONENT_BUILD_PATH}/module/." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    rsync -a -r  ${COMPONENT_CODE_PATH}/target/*.zip ${COMPONENT_BUILD_PATH}/module/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1

    printMessageLog WARN "end build maven project." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog WARN "start copy lib file ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}

    # 复制sdk_wx外壳到组件部署目录
    rsync -a -r ${THIRD_CODE_PATH}/sdk_ws.tar.gz ${COMPONENT_BUILD_PATH}/third/  --exclude=*.svn* >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # 复制core目录到部署目录
    rsync -a -r ${COMPONENT_CODE_PATH}/core/* ${COMPONENT_BUILD_PATH}/core/  --exclude=*.svn* >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1

    printMessageLog WARN "end copy lib file." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog WARN "start copy config files ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 配置文件复制，包含sdkws.properties和bluewhale-site.properties
    rsync -a -r ${THIRD_CODE_PATH}/conf/*.properties ${COMPONENT_BUILD_PATH}/conf/ --exclude=*.svn* >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${THIRD_CODE_PATH}/conf/*.xml ${COMPONENT_BUILD_PATH}/conf/ --exclude=*.svn* >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # 复制指标映射文件
    rsync -a -r ${COMPONENT_CODE_PATH}/conf/*.xml ${COMPONENT_BUILD_PATH}/conf/indexValidation/ --exclude=*.svn* >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # 复制字段枚举文件
    rsync -a -r ${THIRD_CODE_PATH}/conf/*.json ${COMPONENT_BUILD_PATH}/conf/ --exclude=*.svn* >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1

    # om文件复制
    rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/${SDK_WS_NAME}/*.sh ${COMPONENT_BUILD_PATH}/script/ --exclude=build.sh >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/common_dep_util.sh ${COMPONENT_BUILD_PATH}/script/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1

    # 部署配置文件复制
    rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/param.ini ${COMPONENT_BUILD_PATH}/script/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/default.ini ${COMPONENT_BUILD_PATH}/script/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # 修改权限
    chmod 744 ${COMPONENT_BUILD_PATH}/script/*.sh
    chmod 644 ${COMPONENT_BUILD_PATH}/script/*.ini
    printMessageLog WARN "end copy config files ." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
}

# ----------------------------------------------------------------------
# FunctionName:        updateVersion
# createTime  :        2018-08-21
# description :        更新version文件，包含内部版本号和svn提交版本号
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function updateVersion()
{
    printMessageLog WARN "start update version ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    cd ${COMPONENT_BUILD_PATH}/
    if [ ! -f ${COMPONENT_BUILD_PATH}/version ]; then
        touch ${COMPONENT_BUILD_PATH}/version
    fi

    # 更新版本号
    modifyConfig "version" ${VERSION_NUMBER} ${COMPONENT_BUILD_PATH}/version
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "update version number failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    # 获取svn最后提交版本号
    printMessageLog INFO " get svn reversion number." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    local svnRevision=$(getSVNCommitID ${COMPONENT_CODE_PATH})
    if [ ! -z "${svnRevision}" ]; then
        printMessageLog INFO "svn reversion number is ${svnRevision}." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    else
        printMessageLog ERROR "svn reversion number is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 更新svn最后提交版本号
    modifyConfig "svn_revision" ${svnRevision} ${COMPONENT_BUILD_PATH}/version
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "update svn version number failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog WARN "end update version." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        tarComponentPackage
# createTime  :        2018-08-21
# description :        将目录打成tar包
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function tarComponentPackage()
{
    printMessageLog WARN "start compressed component package ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    cd ${COMPONENT_BUILD_PATH}/..
    tar -czvf ${SDK_WS_NAME}_${VERSION_NUMBER}.tar.gz ${SDK_WS_NAME}_${VERSION_NUMBER} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    # 显示进度条
#    showProcessBar 2

    cd ${CURRENT_PATH}
}


main $*
if [ $? -ne 0 ]; then
    printMessageLog ERROR "build ${SDK_WS_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    exit 1
else
    printMessageLog INFO "build ${SDK_WS_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    exit 0
fi
