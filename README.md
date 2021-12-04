# Elasticsearch Index Lifecycle Management
## 배경
Elasticsearch 의 Index Lifecycle 은 본래 curator 라 하는 자체 툴을 사용하였으나,  
최근 ILM(Index Lifecycle Management) 기능을 통해 Elasticsearch 내에서 직접 관리할 수 있게 되었다.  
API 를 통해 손쉽게 설정 가능하며, Kibana 의 UI 로도 구성되어 있어 조작이 간편한 기능이다.  
https://www.elastic.co/guide/en/elasticsearch/reference/current/index-lifecycle-management.html  

다만, ILM 설정은 인덱스 자체가 아닌 Index Template 에 설정하는 것이다.  
현재 운영 중인 Elasticsearch 는 Lagacy 의 Index Template 가 Prefix 이슈로 꽤나 꼬여있는 형태이고, 인덱스마다 삭제 주기가 상이하다.  
묶여 있는 템플릿과 인덱스가 섣불리 건드리다가 주기에 맞지 않는 인덱스를 삭제하게 될 위험이 있었으므로  
대응책으로 쉘 스크립트를 통해 인덱스를 삭제하는 방법을 택하게 되었다.  

## 구성
* **delete_indices.sh** : 실제 인덱스 리스트의 삭제 및 로그 출력을 실행하는 스크립트. Bash Shell 로 작성.
* **indexinfo.txt** : 삭제할 인덱스의 prefix 와 삭제 주기 리스트. 두 정보가 콤마(,)로 나뉘어져 있다.
* **logs/delete_indices.log** : 스크립트로부터 출력된 로그 파일.

## 설정
* delete_indices.sh 스크립트는 매일 아침 9시 25분에 실행된다(Elasticsearch 의 timezone 이 UTC 로 설정되어 있어,  
* 해당 시간에 가까운 동시에 인덱스 생성에 방해되지 않을 시간을 설정)
```
25 9 * * * /home/smileejulie/elklifecycle/delete_indices.sh
```
* delete_indices.log 파일은 logrotate 를 통해 7일간 보관
```
/home/smileejulie/elklifecycle/logs/delete_indices.log {
      weekly
      rotate 7
      compress
      create 644 smileejulie smileejulie
      dateext
}
```

## 과제
* 현재 설정 주기에 해당되는 날짜의 인덱스만을 삭제하도록 설정 -> 주기를 기준으로 이전 인덱스 모두를 삭제할 수 있도록 설정 추가  
쉘 스크립트는 날짜에 대해서도 크기 비교가 가능하므로 해당 설정 또한 가능
* 인덱스와 주기를 txt 파일에서 읽어오는 방식 -> 실제 Elasticsearch 에 해당 정보를 인덱싱한 후 불러오는 방식
* 보안 설정에 대비한 username / password 설정 : hash 처리 등을 고려
