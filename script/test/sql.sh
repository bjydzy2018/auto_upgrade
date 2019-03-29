#!/bin/bash

# 日志颜色
RED_COLOR='\E[1;31m'  
YELOW_COLOR='\E[1;33m' 
BLUE_COLOR='\E[1;34m'  
RESET='\E[0m'

# hive数据库信息
HIVE_PLATFORM_ID=()
# mysql数据库信息
MYSQL_DATABASE=()
MYSQL_CONNECTION_IP=""
MYSQL_USER_NAME=""
MYSQL_PASSWORD=""


function main()
{
    local sqlType=$1
    local filepath=$2

    if [ x"mysql" == x"${sqlType}" ]; then
        upgradeMySQLDatabase
    elif [ x"hive" == x"${sqlType}" ]; then
        upgradeHiveDatabase
    else
        echo -e "${RED_COLOR}[ERROR][Line:${LINENO}] sql type is [${sqlType]], invalid.${RESET}"
        return 1
    fi
    
    return 0
}

# ----------------------------------------------------------------------
# FunctionName:		upgradeMySQLDatabase
# createTime  :		2018-08-26
# description :		升级MySQL数据库，支持多平台，多版本sql升级
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function upgradeMySQLDatabase()
{

}

# ----------------------------------------------------------------------
# FunctionName:		upgradeHiveDatabase
# createTime  :		2018-08-26
# description :		升级Hive数据库，支持多平台，多版本sql升级
# author      :		wenfeng.duan
# ----------------------------------------------------------------------
function upgradeHiveDatabase()
{
    echo "[WARN][Line:${LINENO}] createHiveDatabase() starting ..."
    local sqlFile=$1
    if [ ! -f ${sqlFile} ]; then
        echo "[ERROR][Line:${LINENO}] ${sqlFile}: No such file"
        return 1
    fi

    local fileName=$(basename ${sqlFile})
    local filePath=$(echo ${sqlFile%/*})
    
    for platformID in ${HIVE_PLATFORM_ID[@]}
    do  
        local tmpFile=${filePath}/tmp_${fileName}
        cp -a -r ${sqlFile} ${tmpFile}
        # 判断文件中是否存在use platformid; 若不存在，先增加再执行；若存在，先修改再执行
        local isExist=$(grep "use platformid;" ${tmpFile})
        if [ $? -ne 0 ]; then
            sed -i "1iuse ${platformID};\n" ${tmpFile}
            if [ $? -ne 0 ]; then
                echo "[ERROR][Line:${LINENO}] update file ${tmpFile} failed."
                return 1
            fi
        else
            sed -i "1,2s/platformid/${platformID}/g" ${tmpFile}
            if [ $? -ne 0 ]; then
                echo "[ERROR][Line:${LINENO}] update file ${tmpFile} failed."
                return 1
            fi
        fi
        
        # 执行SQL语句
        echo "[INFO][Line:${LINENO}] hive -f \"${tmpFile}\""
        hive -f "${tmpFile}"
        if [ $? -ne 0 ]; then
            echo "[ERROR][Line:${LINENO}] update hive failed."
            return 1
        else
            echo "[INFO][Line:${LINENO}] update hive-${platformID} successfully."
        fi
    done
    
    echo "[WARN][Line:${LINENO}] createHiveDatabase() end."
    return 0
}


main $*