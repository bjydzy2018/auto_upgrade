#!bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)
PARENT_PATH=$(cd "${CURRENT_PATH}/..";pwd)
source ${PARENT_PATH}/common_build_util.sh

# 组件源代码路径
TASK_PATH=${SVN_ROOT_PATH}/analyse_system/scheduleTask
UPDATE_SQL_PATH=${SVN_ROOT_PATH}/preject_deployment/sql/upgrade

# 初始化日志
initLog ${DATA_MODEL_SERVICE_NAME}

# 版本号，带v
VERSION_NUMBER=""
# 版本号，不带v
VERSION_NUM=""

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
            VERSION_NUM=${versionNumber}
         else
            VERSION_NUMBER=${versionNumber}
            VERSION_NUM=${versionNumber:1}
        fi

        printMessageLog WARN "version number is ${VERSION_NUMBER}." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    else
        printMessageLog ERROR "version number is null, invalid." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    #  初始化组件打包目录
    initTargetDirectory ${DATA_MODEL_SERVICE_NAME} ${VERSION_NUMBER}

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
    
    # 复制配置文件和其他文件
    copyTools
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
    printMessageLog WARN "createDirectory() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}

    if [ -d ${COMPONENT_BUILD_PATH} -a ${COMPONENT_BUILD_PATH} =~ "${SDK_WS_NAME}" ]; then
        rm -rf ${COMPONENT_BUILD_PATH}
    fi

    # 创建cube任务目录
    mkdir -p ${COMPONENT_BUILD_PATH}/task/cube/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create ${COMPONENT_BUILD_PATH}/task/cube/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 创建SQL任务脚本目录
    mkdir -p ${COMPONENT_BUILD_PATH}/task/sql/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create ${COMPONENT_BUILD_PATH}/task/sql/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 创建调度任务脚本目录
    mkdir -p ${COMPONENT_BUILD_PATH}/task/schedule/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create ${COMPONENT_BUILD_PATH}/task/schedule/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 创建工具目录
    mkdir -p ${COMPONENT_BUILD_PATH}/tools/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create ${COMPONENT_BUILD_PATH}/tools/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    # 创建om脚本目录
    mkdir -p ${COMPONENT_BUILD_PATH}/script/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    if [ $? -ne 0 ]; then
        printMessageLog ERROR "create ${COMPONENT_BUILD_PATH}/script/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi

    printMessageLog WARN "createDirectory() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog WARN "buildMaven() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    printMessageLog WARN "buildMaven() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog WARN "copyLibFile() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    printMessageLog WARN "copyLibFile() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
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
    printMessageLog WARN "copyConfigFile() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    printMessageLog INFO "copy sql files" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 复制hive和mysql全量建表语句
    echo "rsync -a -r ${TASK_PATH}/table_task/etl-hive-all.sql ${COMPONENT_BUILD_PATH}/task/sql/hive_all.sql  --exclude=*.svn*"
    rsync -a -r ${TASK_PATH}/table_task/etl-hive-all.sql ${COMPONENT_BUILD_PATH}/task/sql/hive_all.sql  --exclude=*.svn* >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    echo "rsync -a -r ${TASK_PATH}/table_task/etl-mysql-all.sql ${COMPONENT_BUILD_PATH}/task/sql/mysql_all.sql --exclude=*.svn*"
    rsync -a -r ${TASK_PATH}/table_task/etl-mysql-all.sql ${COMPONENT_BUILD_PATH}/task/sql/mysql_all.sql --exclude=*.svn* >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # 复制hive和mysql版本迭代增量建表语句
#    echo "rsync -a -r ${TASK_PATH}/table_task/*-etl-hive-add.sql ${COMPONENT_BUILD_PATH}/task/sql/ --exclude=*.svn*"
#    rsync -a -r ${TASK_PATH}/table_task/*-etl-hive-add.sql ${COMPONENT_BUILD_PATH}/task/sql/ --exclude=*.svn*  >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
#    echo "rsync -a -r ${TASK_PATH}/table_task/*-etl-mysql-add.sql ${COMPONENT_BUILD_PATH}/task/sql/ --exclude=*.svn*"
#    rsync -a -r ${TASK_PATH}/table_task/*-etl-mysql-add.sql ${COMPONENT_BUILD_PATH}/task/sql/ --exclude=*.svn*  >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # 复制hive和mysql手工比对增量建表语句
    echo "rsync -a -r ${UPDATE_SQL_PATH}/${VERSION_NUMBER}_hive_upgrade.sql ${COMPONENT_BUILD_PATH}/task/sql/hive_upgrade.sql --exclude=*.svn*"
    rsync -a -r ${UPDATE_SQL_PATH}/${VERSION_NUMBER}_hive_upgrade.sql ${COMPONENT_BUILD_PATH}/task/sql/${VERSION_NUMBER}_hive_upgrade.sql --exclude=*.svn*  >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    echo "rsync -a -r ${UPDATE_SQL_PATH}/${VERSION_NUMBER}_mysql_upgrade.sql/ ${COMPONENT_BUILD_PATH}/task/sql/mysql_upgrade.sql --exclude=*.svn*"
    rsync -a -r ${UPDATE_SQL_PATH}/${VERSION_NUMBER}_mysql_upgrade.sql ${COMPONENT_BUILD_PATH}/task/sql/${VERSION_NUMBER}_mysql_upgrade.sql --exclude=*.svn*  >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    printMessageLog INFO "copy schedule files" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 复制调度任务
    echo "rsync -a -r ${TASK_PATH}/schedule_task/etl_all_task_hive.xml ${COMPONENT_BUILD_PATH}/task/schedule/etl_all_task_hive.xml --exclude=*.svn*"
    rsync -a -r ${TASK_PATH}/schedule_task/etl_all_task_hive.xml ${COMPONENT_BUILD_PATH}/task/schedule/etl_all_task_hive.xml --exclude=*.svn*  >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    printMessageLog INFO "copy cube files" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 复制cube元数据
    # 获取zip文件列表
    ZIP_FILE_LIST=$(ls ${TASK_PATH}/cube_task/ | grep -E "backup_([0-9]).([0-9]{2}).zip" | sort -k1.5n)
    for file in ${ZIP_FILE_LIST[@]}
    do
        local fileName=$(basename ${file} .zip)
        echo "rsync -a -r ${TASK_PATH}/cube_task/${file} ${COMPONENT_BUILD_PATH}/task/cube/ --exclude=*.svn*"
        rsync -a -r ${TASK_PATH}/cube_task/${file} ${COMPONENT_BUILD_PATH}/task/cube/ --exclude=*.svn*  >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        echo "rsync -a -r ${TASK_PATH}/cube_task/${fileName}_metadata_immigration.properties ${COMPONENT_BUILD_PATH}/task/cube/ --exclude=*.svn*"
        rsync -a -r ${TASK_PATH}/cube_task/${fileName}_metadata_immigration.properties ${COMPONENT_BUILD_PATH}/task/cube/ --exclude=*.svn*  >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    done

    printMessageLog INFO "copy OM files" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 复制om文件
    echo "rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/${DATA_MODEL_SERVICE_NAME}/*.sh ${COMPONENT_BUILD_PATH}/script/ --exclude=build.sh"
    rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/${DATA_MODEL_SERVICE_NAME}/*.sh ${COMPONENT_BUILD_PATH}/script/ --exclude=build.sh >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    echo "rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/common_dep_util.sh ${COMPONENT_BUILD_PATH}/script/"
    rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/common_dep_util.sh ${COMPONENT_BUILD_PATH}/script/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # 部署配置文件复制
    echo "rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/param.ini ${COMPONENT_BUILD_PATH}/script/"
    rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/param.ini ${COMPONENT_BUILD_PATH}/script/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    echo "rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/default.ini ${COMPONENT_BUILD_PATH}/script/"
    rsync -a -r ${SVN_ROOT_PATH}/preject_deployment/script/default.ini ${COMPONENT_BUILD_PATH}/script/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # 修改权限
    printMessageLog INFO "modify permission" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    chmod 744 ${COMPONENT_BUILD_PATH}/script/*.sh
    chmod 644 ${COMPONENT_BUILD_PATH}/script/*.ini
    chmod 644 ${COMPONENT_BUILD_PATH}/task/*.sql
    chmod 644 ${COMPONENT_BUILD_PATH}/task/*.xml
    chmod 644 ${COMPONENT_BUILD_PATH}/task/*.properties
    
    printMessageLog WARN "copyConfigFile() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:        copyTools
# createTime  :        2018-08-21
# description :        复制相关工具到对应目录
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function copyTools()
{
    printMessageLog WARN "copyTools() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    printMessageLog INFO "copy create view tool" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 复制创建视图文件
    echo "rsync -a -r ${SVN_ROOT_PATH}/analyse_system/tools/hive/hive_create_view.sh ${COMPONENT_BUILD_PATH}/tools/"
    rsync -a -r ${SVN_ROOT_PATH}/analyse_system/tools/hive/hive_create_view.sh ${COMPONENT_BUILD_PATH}/tools/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # 修改权限
    printMessageLog INFO "modify permission" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    chmod 744 ${COMPONENT_BUILD_PATH}/tools/*.sh
    
    printMessageLog WARN "copyTools() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# --------------------------------------------------------------------------------------------------------------------------------------------
# FunctionName:        updateVersion
# createTime  :        2018-08-21
# description :        更新version文件，包含版本号和commitid，报表平台除外，暂时使用version.php，但需要更新版本号
# author      :        wenfeng.duan
# --------------------------------------------------------------------------------------------------------------------------------------------
function updateVersion()
{
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
    tar -czvf ${DATA_MODEL_SERVICE_NAME}_${VERSION_NUMBER}.tar.gz ${DATA_MODEL_SERVICE_NAME}_${VERSION_NUMBER} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    # 显示进度条
#    showProcessBar 2

    cd ${CURRENT_PATH}
}


main $*
if [ $? -ne 0 ]; then
    printMessageLog ERROR "build ${DATA_MODEL_SERVICE_NAME} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    exit 1
else
    printMessageLog INFO "build ${DATA_MODEL_SERVICE_NAME} successfully." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    exit 0
fi
