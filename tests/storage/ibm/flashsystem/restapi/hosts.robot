*** Settings ***
Documentation     storage::ibm::flashsystem::restapi::plugin

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}flashsystem.mockoon.json

${CMD}             ${CENTREON_PLUGINS}
...                --plugin=storage::ibm::flashsystem::restapi::plugin
...                --mode=hosts
...                --hostname=${HOSTNAME}
...                --proto=http
...                --port=${APIPORT}
...                --api-username=user
...                --api-password=pass
...                --statefile-dir=/tmp


*** Test Cases ***
hosts ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    WARNING: Host 'host-29' status: offline, ports: 4, partition: partition-b - Host 'host-43' status: offline, ports: 4, partition: partition-b - Host 'host-51' status: offline, ports: 4, partition: partition-b - Host 'host-54' status: offline, ports: 4, partition: partition-b | 'hosts.detected.count'=12;;;0; 'hosts.online.count'=8;;;0; 'hosts.offline.count'=4;;;0; 'hosts.degraded.count'=0;;;0;
    ...    2
    ...    --include-partition='partition-a'
    ...    OK: Hosts: 8 declared, 8 online, 0 offline, 0 degraded - All hosts are online | 'hosts.detected.count'=8;;;0; 'hosts.online.count'=8;;;0; 'hosts.offline.count'=0;;;0; 'hosts.degraded.count'=0;;;0;
    ...    3
    ...    --critical-status='\\\%{status} =~ /offline/'
    ...    CRITICAL: Host 'host-29' status: offline, ports: 4, partition: partition-b - Host 'host-43' status: offline, ports: 4, partition: partition-b - Host 'host-51' status: offline, ports: 4, partition: partition-b - Host 'host-54' status: offline, ports: 4, partition: partition-b | 'hosts.detected.count'=12;;;0; 'hosts.online.count'=8;;;0; 'hosts.offline.count'=4;;;0; 'hosts.degraded.count'=0;;;0;
    ...    4
    ...    --include-name='^host-2'
    ...    WARNING: Host 'host-29' status: offline, ports: 4, partition: partition-b | 'hosts.detected.count'=1;;;0; 'hosts.online.count'=0;;;0; 'hosts.offline.count'=1;;;0; 'hosts.degraded.count'=0;;;0;
    ...    5
    ...    --exclude-partition='partition-b'
    ...    OK: Hosts: 8 declared, 8 online, 0 offline, 0 degraded - All hosts are online | 'hosts.detected.count'=8;;;0; 'hosts.online.count'=8;;;0; 'hosts.offline.count'=0;;;0; 'hosts.degraded.count'=0;;;0;

hosts discovery ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>name</element> <element>status</element> <element>partition_name</element> <element>host_cluster_name</element> <element>port_count</element> </data>
    ...    2
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label host_cluster_name="" name="host-01" partition_name="partition-a" port_count="2" status="online"/> <label host_cluster_name="" name="host-02" partition_name="partition-a" port_count="2" status="online"/> <label host_cluster_name="" name="host-03" partition_name="partition-a" port_count="2" status="online"/> <label host_cluster_name="" name="host-04" partition_name="partition-a" port_count="2" status="online"/> <label host_cluster_name="" name="host-05" partition_name="partition-a" port_count="2" status="online"/> <label host_cluster_name="" name="host-06" partition_name="partition-a" port_count="2" status="online"/> <label host_cluster_name="" name="host-07" partition_name="partition-a" port_count="2" status="online"/> <label host_cluster_name="" name="host-08" partition_name="partition-a" port_count="2" status="online"/> <label host_cluster_name="" name="host-29" partition_name="partition-b" port_count="4" status="offline"/> <label host_cluster_name="" name="host-43" partition_name="partition-b" port_count="4" status="offline"/> <label host_cluster_name="" name="host-51" partition_name="partition-b" port_count="4" status="offline"/> <label host_cluster_name="" name="host-54" partition_name="partition-b" port_count="4" status="offline"/> </data>
