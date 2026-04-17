*** Settings ***
Documentation       Cloud Docker REST API Container cgroup V1

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}docker-cgroupv1.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::docker::restapi::plugin
...                 --mode=container-usage
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}


*** Test Cases ***
Container cgroupv1 usage ${tc}
    [Tags]    cloud    kubernetes

    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extraoptions
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Container 'containerId' state: running, cpu : Buffer creation, memory total: 7.47 GB used: 358.07 MB (4.68%) free: 7.12 GB (95.32%), read-iops : Buffer creation, write-iops : Buffer creation - Container 'containerId.eth0' traffic-in : Buffer creation, traffic-out : Buffer creation | 'memory_used'=375459840B;;;0;8025042944
    ...    2
    ...    ${EMPTY}
    ...    OK: Container 'containerId' state: running, cpu usage: 0.00 %, memory total: 7.47 GB used: 358.07 MB (4.68%) free: 7.12 GB (95.32%), read IOPs: 0.00, write IOPs: 0.00 - Container 'containerId.eth0' traffic in: 0.00 b/s, traffic out: 0.00 b/s | 'cpu'=0.00%;;;0;100 'memory_used'=375459840B;;;0;8025042944 'read_iops'=0.00iops;;;0; 'write_iops'=0.00iops;;;0; 'traffic_in'=0.00b/s;;;0; 'traffic_out'=0.00b/s;;;0;
    ...    3
    ...    --use-name --no-stats
    ...    OK: Container '/containerName' state: running
    ...    4
    ...    --critical-container-status='\\\%{state}=~/running/'
    ...    CRITICAL: Container 'containerId' state: running | 'cpu'=0.00%;;;0;100 'memory_used'=79664947B;;;0;8217579520 'read_iops'=0.00iops;;;0; 'write_iops'=0.00iops;;;0; 'traffic_in_containerId.eth0'=0.00b/s;;;0; 'traffic_out_containerId.eth0'=0.00b/s;;;0; 'traffic_in_containerId.eth5'=0.00b/s;;;0; 'traffic_out_containerId.eth5'=0.00b/s;;;0;
