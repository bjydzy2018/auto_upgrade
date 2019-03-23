#！/bin/bash

function read_fun()
{
    read -p "请输入是否继续，Y[yes] or N[no]: " input

    if [ x"yes" == x"${input}" -o x"Y" == x"${input}" ]; then
        echo "参入参数为：${input}"
        return 0
    elif [ x"no" == x"${input}" -o x"N" == x"${input}" ]; then
        echo "参入参数为：${input}，结束"
        return 1
    else
        echo "输入参数有误"
        return 1
    fi
}

function main()
{
    read_fun
    
    if [ $? -ne 0 ]; then
        echo "非法退出"
    else
        echo "正常退出"
    fi
}

main $*