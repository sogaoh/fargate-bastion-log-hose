#!/bin/bash

# コマンド実行履歴を保存する
function log_history {
    logger -p user.info -t history -i "$$, $USER, $PWD, $BASH_COMMAND"
}
readonly -f log_history
trap log_history DEBUG EXIT

SLEEP_SECONDS="${1:-900}"  # 第1引数が指定されていない場合は900秒（15分）をデフォルト値とする
LOGIN_USER="exist"

echo "Check interval: $SLEEP_SECONDS seconds"
while :
do
    sleep $SLEEP_SECONDS
    LOGIN_USER_NUMBER=$(ps -ef | grep ssm-session-worker | grep -v grep | wc -l)

    if [ "$LOGIN_USER_NUMBER" != "0" ]; then
        LOGIN_USER="exist"
    else
        if [ "$LOGIN_USER" = "not exist" ]; then
            echo "No login user detected. Exiting..."
            exit 0
        else
            LOGIN_USER="not exist"
        fi
    fi
    echo "Current status: $LOGIN_USER"
done
