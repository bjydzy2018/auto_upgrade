#!/usr/bin/env bash#!/bin/bash

INIFILE=""
SECTION=""
ITEM=""
NEWVAL=""

function ReadINIfile()
{
    ReadINI=`awk -F '=' '/\['$SECTION'\]/{a=1}a==1&&$1~/'$ITEM'/{print $2;exit}' $INIFILE`
    echo $ReadINI
}

function WriteINIfile()
{
    WriteINI=`sed -i "/^\[$SECTION\]/,/^\[/ {/^\[$SECTION\]/b;/^\[/b;s/^$ITEM*=.*/$ITEM=$NEWVAL/g;}" $INIFILE`
    echo $WriteINI
}

function main()
{
    INIFILE=$1
    SECTION=$2
    ITEM=$3
    NEWVAL=$4

    if [ -z "$4" ]; then
        ReadINIfile $1 $2 $3
    else
        WriteINIfile $1 $2 $3 $4
    fi
}

main $*