#!/bin/bash

# ----------------------------------------------------------------------
# FunctionName:        isDigit
# createTime  :        2019-03-29
# description :        判断是否为数字
# author      :        wenfeng.duan
# ----------------------------------------------------------------------
function isDigit()
{
    local str=$1
    if [ -z "${str}" ]; then
        echo "param is null, invalid."
        return 1;
    fi
    
    if grep '^[[:digit:]]*$' <<< "${str}";then 
        echo "${str} is number."
        return 0;
    else 
        echo "${str} is not number." 
        return 1;
    fi
}

isDigit $*