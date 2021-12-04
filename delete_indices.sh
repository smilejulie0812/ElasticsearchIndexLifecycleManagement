#!/bin/bash
#/home/smileejulie/.profile

############# SCRIPT INFO #############
# SCRIPT NAME : delete_indices.sh
# SCRIPT GOLE : INDEX LIFECYCLE DELETE MULTIPLE INDICES
# AUTHOR : smileejulie
# CREATE DATE : 2021.08.10
# REVICE DATE : 2021.12.04
#######################################

### VARIABLES
ILM_FILE="/home/smileejulie/elklifecycle/indexinfo.txt"
IDX_INFO=$(cat $ILM_FILE)

LOG_DIR="/home/smileejulie/elklifecycle/logs"
LOG_FILE="delete_indices.log"

DOMAIN="localhost"
USERNAME="elastic"
PASSWORD="passward"

### FUNCION FOR LOGGING
function printLog()
{
    LOG_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${LOG_TIME}] ${1}" >> ${LOG_DIR}/${LOG_FILE}
}

### CHECK INDEX EXIST
for INDEX_LIST in $IDX_INFO;
do
    ### 인덱스 리스트 안의 prefix 와 주기 정보를 통해 curl 명령어로 출력할 삭제 대상 인덱스 헤더 생성
    INDEX_PREFIX=$(echo $INDEX_LIST | cut -d',' -f 1)
    ILM_DAY=$(echo $INDEX_LIST | cut -d',' -f 2)
    TODAY=$(date -d "$ILM_DAY days ago" +%Y.%m.%d)
    INDEX_HEADER="${INDEX_PREFIX}-${TODAY}"

    ### index pattern 으로 grep 한 삭제 대상 인덱스 리스트 출력
    #TODAY_INDEX_INFO=$(curl -s -XGET "http://${USERNAME}:${PASSWORD}@${DOMAIN}:9200/_cat/indices" | grep $INDEX_HEADER)      # ELASTIC SECURITY SETTING EXISTS
    TODAY_INDEX_INFO=$(curl -s -XGET "http://${DOMAIN}:9200/_cat/indices" | grep $INDEX_HEADER)                               # ELASTIC SECURITY SETTING ABSENT

    ### 삭제 대상 인덱스 리스트로부터 인덱스 health/state/name 분리
    LEN=${#TODAY_INDEX_INFO[@]}
    INDEX_HEAL=($(echo -e "$TODAY_INDEX_INFO" | awk '{print $1}'))
    INDEX_STAT=($(echo -e "$TODAY_INDEX_INFO" | awk '{print $2}'))
    INDEX_NAME=($(echo -e "$TODAY_INDEX_INFO" | awk '{print $3}'))

    ### 삭제 대상 인덱스가 존재하지 않을 경우
    if [ $LEN -eq 0 ]; then
        ### INDEX ABSENT
        printLog "There is no index ${INDEX_HEADER[i]} to delete"
        continue
    fi

    for (( i=0 ; i < $LEN ; i++ ));
    do
        ### 인덱스 패턴과 맞지 않는 인덱스가 대상일 경우
        CHECK_INDEX_HEADER=$(echo $INDEX_NAME | egrep "^$INDEX_HEADER" | wc -l)
        if [ $CHECK_INDEX_HEADER -eq 0 ]; then
                printLog "Index pattern miss match. $INDEX_NAME vs $INDEX_HEADER"
                continue
        fi

        ### INDEX EXIST
        if [ -n "${INDEX_NAME[i]}" ]; then
        ### CHECK INDEX STATEMENT
            printLog "Delete index \"${INDEX_NAME[i]}\""

            if [[ "${INDEX_HEAL[i]}" == "green" ]] && [[ "${INDEX_STAT[i]}" == "open" ]]; then
                curl -XDELETE "http://${DOMAIN}:9200/${INDEX_NAME[i]}" >> ${LOG_DIR}/${LOG} 2>&1
                    sleep 3

                ### CHECK DELETE SUCCESS
                CHECK_INDEX_DELETED=$(curl -s -XGET "http://${DOMAIN}:9200/_cat/indices" | grep $INDEX_HEADER)
                if [[ -z "$CHECK_INDEX_DELETED" ]]; then
                    ### DELETE SUCCESS INDEX
                    printLog "Delete Success index \"${INDEX_NAME[i]}\""
                else
                    ### DELETE FAILURE INDEX: CURL FAILURE ISSUE
                    printLog "Delete Failure index \"${INDEX_NAME[i]}\" : check file $LOG_FILE"
                fi

            else
                ### DELETE FAILURE INDEX: INDEX STATUS ISSUE
                printLog "Delete Failure index \"${INDEX_NAME[i]}\" : check index status [\"${INDEX_HEAL[i]}\"/\"${INDEX_STAT[i]}\"]"
            fi
        fi
    done
done
