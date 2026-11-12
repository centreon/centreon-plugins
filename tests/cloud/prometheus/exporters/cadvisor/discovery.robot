*** Settings ***
Documentation       Prometheus cAdvisor exporter - discovery mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::prometheus::exporters::cadvisor::plugin
...                 --mode=discovery
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http


*** Test Cases ***
Discovery ${tc}
    [Tags]    cloud    prometheus    cadvisor

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Json    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --url-path=/api/v1
    ...    {"discovered_items":10,"duration":0,"end_time":0,"results":[{"container_image":"","container_name":"","id":"default/batch-crashloop","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"default","kubernetes_pod":"batch-crashloop","name":"batch-crashloop","node":"ks-node-01","source":"kubernetes","type":"pod"},{"container_image":"","container_name":"","id":"default/web-7d9f8b6c5-q8z7m","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"default","kubernetes_pod":"web-7d9f8b6c5-q8z7m","name":"web-7d9f8b6c5-q8z7m","node":"ks-node-01","source":"kubernetes","type":"pod"},{"container_image":"","container_name":"","id":"default/web-7d9f8b6c5-x2k4p","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"default","kubernetes_pod":"web-7d9f8b6c5-x2k4p","name":"web-7d9f8b6c5-x2k4p","node":"ks-node-01","source":"kubernetes","type":"pod"},{"container_image":"","container_name":"","id":"monitoring/alertmanager-main-0","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"monitoring","kubernetes_pod":"alertmanager-main-0","name":"alertmanager-main-0","node":"ks-node-01","source":"kubernetes","type":"pod"},{"container_image":"haproxy:2.8","container_name":"haproxy","id":"10.224.4.59:10250/haproxy","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"","kubernetes_pod":"","name":"haproxy","node":"ks-node-01","source":"standalone","type":"container"},{"container_image":"nginx:1.25","container_name":"nginx","id":"default/web-7d9f8b6c5-q8z7m/nginx","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"default","kubernetes_pod":"web-7d9f8b6c5-q8z7m","name":"nginx","node":"ks-node-01","source":"kubernetes","type":"container"},{"container_image":"nginx:1.25","container_name":"nginx","id":"default/web-7d9f8b6c5-x2k4p/nginx","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"default","kubernetes_pod":"web-7d9f8b6c5-x2k4p","name":"nginx","node":"ks-node-01","source":"kubernetes","type":"container"},{"container_image":"haproxy:2.8","container_name":"haproxy","id":"docker-b:8080/haproxy","instance":"docker-b:8080","job":"kubelet","kubernetes_namespace":"","kubernetes_pod":"","name":"haproxy","node":"docker-b","source":"standalone","type":"container"},{"container_image":"quay.io/prometheus/alertmanager:v0.26.0","container_name":"alertmanager","id":"monitoring/alertmanager-main-0/alertmanager","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"monitoring","kubernetes_pod":"alertmanager-main-0","name":"alertmanager","node":"ks-node-01","source":"kubernetes","type":"container"},{"container_image":"quay.io/prometheus-operator/prometheus-config-reloader:v0.70.0","container_name":"config-reloader","id":"monitoring/alertmanager-main-0/config-reloader","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"monitoring","kubernetes_pod":"alertmanager-main-0","name":"config-reloader","node":"ks-node-01","source":"kubernetes","type":"container"}],"start_time":0}
    ...    2
    ...    --url-path=/api/v1 --extra-filter='namespace="monitoring"'
    ...    {"discovered_items":3,"duration":0,"end_time":0,"results":[{"container_image":"","container_name":"","id":"monitoring/alertmanager-main-0","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"monitoring","kubernetes_pod":"alertmanager-main-0","name":"alertmanager-main-0","node":"ks-node-01","source":"kubernetes","type":"pod"},{"container_image":"quay.io/prometheus/alertmanager:v0.26.0","container_name":"alertmanager","id":"monitoring/alertmanager-main-0/alertmanager","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"monitoring","kubernetes_pod":"alertmanager-main-0","name":"alertmanager","node":"ks-node-01","source":"kubernetes","type":"container"},{"container_image":"quay.io/prometheus-operator/prometheus-config-reloader:v0.70.0","container_name":"config-reloader","id":"monitoring/alertmanager-main-0/config-reloader","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"monitoring","kubernetes_pod":"alertmanager-main-0","name":"config-reloader","node":"ks-node-01","source":"kubernetes","type":"container"}],"start_time":0}
    ...    3
    ...    --url-path=/legacy/api/v1 --container-label=container_name --pod-label=pod_name
    ...    {"discovered_items":9,"duration":0,"end_time":0,"results":[{"container_image":"","container_name":"","id":"default/batch-crashloop","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"default","kubernetes_pod":"batch-crashloop","name":"batch-crashloop","node":"ks-node-01","source":"kubernetes","type":"pod"},{"container_image":"","container_name":"","id":"default/web-7d9f8b6c5-q8z7m","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"default","kubernetes_pod":"web-7d9f8b6c5-q8z7m","name":"web-7d9f8b6c5-q8z7m","node":"ks-node-01","source":"kubernetes","type":"pod"},{"container_image":"","container_name":"","id":"default/web-7d9f8b6c5-x2k4p","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"default","kubernetes_pod":"web-7d9f8b6c5-x2k4p","name":"web-7d9f8b6c5-x2k4p","node":"ks-node-01","source":"kubernetes","type":"pod"},{"container_image":"","container_name":"","id":"monitoring/alertmanager-main-0","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"monitoring","kubernetes_pod":"alertmanager-main-0","name":"alertmanager-main-0","node":"ks-node-01","source":"kubernetes","type":"pod"},{"container_image":"haproxy:2.8","container_name":"haproxy","id":"10.224.4.59:10250/haproxy","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"","kubernetes_pod":"","name":"haproxy","node":"ks-node-01","source":"standalone","type":"container"},{"container_image":"nginx:1.25","container_name":"nginx","id":"default/web-7d9f8b6c5-q8z7m/nginx","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"default","kubernetes_pod":"web-7d9f8b6c5-q8z7m","name":"nginx","node":"ks-node-01","source":"kubernetes","type":"container"},{"container_image":"nginx:1.25","container_name":"nginx","id":"default/web-7d9f8b6c5-x2k4p/nginx","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"default","kubernetes_pod":"web-7d9f8b6c5-x2k4p","name":"nginx","node":"ks-node-01","source":"kubernetes","type":"container"},{"container_image":"quay.io/prometheus/alertmanager:v0.26.0","container_name":"alertmanager","id":"monitoring/alertmanager-main-0/alertmanager","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"monitoring","kubernetes_pod":"alertmanager-main-0","name":"alertmanager","node":"ks-node-01","source":"kubernetes","type":"container"},{"container_image":"quay.io/prometheus-operator/prometheus-config-reloader:v0.70.0","container_name":"config-reloader","id":"monitoring/alertmanager-main-0/config-reloader","instance":"10.224.4.59:10250","job":"kubelet","kubernetes_namespace":"monitoring","kubernetes_pod":"alertmanager-main-0","name":"config-reloader","node":"ks-node-01","source":"kubernetes","type":"container"}],"start_time":0}

Discovery wrong label option
    [Tags]    cloud    prometheus    cadvisor

    ${command}    Catenate
    ...    ${CMD}
    ...    --url-path=/api/v1
    ...    --pod-label='pod name'

    Ctn Run Command And Check Result As Strings
    ...    ${command}
    ...    UNKNOWN: Need to specify --pod-label option as a Prometheus label name.
