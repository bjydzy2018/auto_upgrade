#!bin/bash

function main()
{
    local input=$*
    local str="   aaaa bbb  cccc        dddd                "
    
    if [ ! -z "${input}" ]; then
        str="${input}"
    fi
    
    echo "str=${str}="

    str_trim=$(trim "${str}")
    echo "str=${str_trim}="

    str_trim_before=$(trimBefore "${str}")
    echo "str=${str_trim_before}="

    str_trim_after=$(trimAfter "${str}")
    echo "str=${str_trim_after}="
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

main $*