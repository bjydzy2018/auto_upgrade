#!/bin/bash

CLASS_NAME=$(basename $0)
CURRENT_PATH=$(cd "$(dirname "$0")";pwd)

source ${CURRENT_PATH}/common_dep_util.sh

readonly LOG_FILE_NAME_PREFIX=`echo $(basename ${CLASS_NAME} .sh)`
LOG_FILE_NAME=${REPORTER_SYSTEM_NAME}_${LOG_FILE_NAME_PREFIX}.log
# 初始化日志
initLog ${REPORTER_SYSTEM_NAME} ${LOG_FILE_NAME}

# 组件新部署目录
readonly DEPLOY_PATH=${DEPLOY_ROOT_PATH}/${MICRO_SERVICE_NAME}/${REPORTER_SYSTEM_NAME}

# 组件老部署目录
readonly OLD_DEPLOY_PATH=${WWW_PATH}/bigdata

# ----------------------------------------------------------------------
# FunctionName:		main
# createTime  :		2018-08-24
# description :		组件卸载主函数入口
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function main()
{
    if [ x"$1" = x"old" ]; then
        # 新版本组件卸载
        uninstall_old
        [ $? -ne 0 ] && return 1
    elif [ x"$1" = x"new" ]; then
        # 新版本组件卸载
        uninstall_new
        [ $? -ne 0 ] && return 1
    else
        # 老版本组件卸载
        uninstall_old
        [ $? -ne 0 ] && return 1
        
        # 新版本组件卸载
        uninstall_new
        [ $? -ne 0 ] && return 1
    fi
    
    # 删除软链接
    deleteSoftLinks
    [ $? -ne 0 ] && return 1
    
    # 删除crontab任务
    clearCrontab
    [ $? -ne 0 ] && return 1
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		uninstall_old
# createTime  :		2018-08-24
# description :		老版本组件
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function uninstall_old()
{
    printMessageLog WARN "uninstall_old() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 老版本组件卸载
    printMessageLog INFO "check directory: ${OLD_DEPLOY_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    if [ -d ${OLD_DEPLOY_PATH} ]; then
        # 先备份整个目录
        backup_directory ${OLD_DEPLOY_PATH}/../ "bigdata"
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "backup ${OLD_DEPLOY_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
        
        # 再删除整个目录
        printMessageLog INFO "delete directory: ${OLD_DEPLOY_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        rm -rf ${OLD_DEPLOY_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "delete ${OLD_DEPLOY_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
    fi
    
    printMessageLog INFO "check directory: ${OLD_DEPLOY_PATH}/../np/" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    if [ -d ${OLD_DEPLOY_PATH}/../np/ ]; then
        # 先备份整个目录
        backup_directory ${OLD_DEPLOY_PATH}/../ "np"
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "backup ${OLD_DEPLOY_PATH}/../np/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
    
        # 再删除整个目录
        printMessageLog INFO "delete directory: ${OLD_DEPLOY_PATH}/../np/" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        rm -rf ${OLD_DEPLOY_PATH}/../np/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "delete ${OLD_DEPLOY_PATH}../np/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
    fi
    
    printMessageLog WARN "uninstall_old() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		uninstall_new
# createTime  :		2018-08-24
# description :		新版本组件
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function uninstall_new()
{
    printMessageLog WARN "uninstall_new() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 新版本组件卸载
    printMessageLog INFO "check directory: ${DEPLOY_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    if [ -d ${DEPLOY_PATH} ]; then
        # 先备份整个目录
        backup_directory ${DEPLOY_PATH}/../ ${REPORTER_SYSTEM_NAME}
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "backup ${DEPLOY_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
    
        # 再删除整个目录
        printMessageLog INFO "delete directory: ${DEPLOY_PATH}" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        rm -rf ${DEPLOY_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "delete ${DEPLOY_PATH} failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
    fi
    
    printMessageLog INFO "check directory: ${DEPLOY_PATH}/../np/" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    if [ -d ${DEPLOY_PATH}/../np/ ]; then
        # 先备份整个目录
        backup_directory ${DEPLOY_PATH}/../ "np"
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "backup ${DEPLOY_PATH}/../np/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
    
        # 再删除整个目录
        printMessageLog INFO "delete directory: ${DEPLOY_PATH}/../np/" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        rm -rf ${DEPLOY_PATH}/../np/ >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
        if [ $? -ne 0 ]; then
            printMessageLog ERROR "delete ${DEPLOY_PATH}../np/ failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
            return 1
        fi
    fi
    
    printMessageLog WARN "uninstall_new() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		deleteSoftLinks
# createTime  :		2019-01-13
# description :		删除软链接
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function deleteSoftLinks()
{
    printMessageLog WARN "deleteSoftLinks() starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    
    # 删除软链接
    if [ -d ${WWW_PATH}/bigdata ]; then
        printMessageLog INFO "delete directory: ${WWW_PATH}/bigdata" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        rm -rf ${WWW_PATH}/bigdata >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    fi
    
    printMessageLog WARN "deleteSoftLinks() end." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		clearCrontab
# createTime  :		2018-08-24
# description :		删除crontab任务
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function clearCrontab()
{
    printMessageLog INFO "clearCrontab starting ..." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
    # 备份crontab任务列表
    crontab -l > ${CURRENT_PATH}/$(getToday)_uninstall.crontab >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    backupFile ${CURRENT_PATH}/$(getToday)_uninstall.crontab ${BACKUP_ROOT_PATH}/${REPORTER_SYSTEM_NAME}/crontab "crontab"

    if [ $? -eq 0 ]; then
        printMessageLog DEBUG "rm -rf ${CURRENT_PATH}/$(getToday)_install.crontab" ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        rm -rf ${CURRENT_PATH}/$(getToday)_install.crontab
    else
        printMessageLog ERROR "backup crontab failed." ${CLASS_NAME} ${FUNCNAME} ${LINENO}
        return 1
    fi
    
    # 删除crontab任务
    sed -i '/sync_aaa_data_to_local.php/d' ${CRONTAB_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    sed -i '/sync_cms_data_to_local.php/d' ${CRONTAB_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    sed -i '/upload_aaa_csv_to_hadoop.php/d' ${CRONTAB_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    sed -i '/upload_cms_csv_to_hadoop.php/d' ${CRONTAB_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    sed -i '/sync_rank_data.php/d' ${CRONTAB_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    sed -i '/get_task_status.php/d' ${CRONTAB_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    sed -i '/sync_cms_playbill_data_to_redis.php/d' ${CRONTAB_PATH} >> ${LOG_PATH}/${LOG_FILE_NAME} 2>&1
    
    # 删除空行
    sed -i '/^$/d' ${CRONTAB_PATH}
    
    # 重启crontab
    service crond restart

    return 0
}

main $*