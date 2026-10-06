*** Settings ***
Documentation     apps::backup::veeam::vbr::restapi::plugin

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}veeam-vbr.mockoon.json

${CMD}             ${CENTREON_PLUGINS}
...                --plugin=apps::backup::veeam::vbr::restapi::plugin
...                --mode=managed-servers
...                --http-peer-addr=${HOSTNAME}
...                --port=${APIPORT}
...                --proto=http
...                --api-username=username
...                --api-password=password


*** Test Cases ***
Managed servers ${tc}
    [Tags]    apps    backup    veeam    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    --hostname=${hostname}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    hostname
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    vbr.example.com
    ...    ${EMPTY}
    ...    CRITICAL: managed server 'windows02.example.com' [type: WindowsHost] status: Unavailable | 'managedservers.detected.count'=4;;;0; 'managedservers.available.count'=3;;;0;4 'managedservers.unavailable.count'=1;;;0;4
    ...    2
    ...    vbr.example.com
    ...    --exclude-name=windows02
    ...    OK: Number of managed servers detected: 3, available: 3, unavailable: 0 - All managed servers are ok | 'managedservers.detected.count'=3;;;0; 'managedservers.available.count'=3;;;0;3 'managedservers.unavailable.count'=0;;;0;3
    ...    3
    ...    vbr.example.com
    ...    --include-type=ViHost
    ...    OK: Number of managed servers detected: 1, available: 1, unavailable: 0 - managed server 'vcenter01.example.com' [type: ViHost] status: Available | 'managedservers.detected.count'=1;;;0; 'managedservers.available.count'=1;;;0;1 'managedservers.unavailable.count'=0;;;0;1
    ...    4
    ...    vbr.example.com
    ...    --include-name='^windows' --exclude-type=LinuxHost
    ...    CRITICAL: managed server 'windows02.example.com' [type: WindowsHost] status: Unavailable | 'managedservers.detected.count'=2;;;0; 'managedservers.available.count'=1;;;0;2 'managedservers.unavailable.count'=1;;;0;2
    ...    5
    ...    vbr.example.com
    ...    --critical-server-status='' --warning-server-status='\\\%{type} eq "ViHost"'
    ...    WARNING: managed server 'vcenter01.example.com' [type: ViHost] status: Available | 'managedservers.detected.count'=4;;;0; 'managedservers.available.count'=3;;;0;4 'managedservers.unavailable.count'=1;;;0;4
    ...    6
    ...    vbr.example.com
    ...    --critical-server-status='' --critical-servers-unavailable=0
    ...    CRITICAL: Number of managed servers unavailable: 1 | 'managedservers.detected.count'=4;;;0; 'managedservers.available.count'=3;;;0;4 'managedservers.unavailable.count'=1;;0:0;0;4
    ...    7
    ...    no-servers.example.com
    ...    ${EMPTY}
    ...    UNKNOWN: Number of managed servers detected: 0 | 'managedservers.detected.count'=0;;;0; 'managedservers.available.count'=0;;;0;0 'managedservers.unavailable.count'=0;;;0;0

Managed servers discovery ${tc}
    [Tags]    apps    backup    veeam    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    --hostname=${hostname}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    hostname
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    vbr.example.com
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>id</element> <element>name</element> <element>type</element> <element>status</element> </data>
    ...    2
    ...    vbr.example.com
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label id="33333333-0000-0000-0000-000000000001" name="linux01.example.com" status="Available" type="LinuxHost"/> <label id="33333333-0000-0000-0000-000000000004" name="vcenter01.example.com" status="Available" type="ViHost"/> <label id="33333333-0000-0000-0000-000000000002" name="windows01.example.com" status="Available" type="WindowsHost"/> <label id="33333333-0000-0000-0000-000000000003" name="windows02.example.com" status="Unavailable" type="WindowsHost"/> </data>
    ...    3
    ...    vbr.example.com
    ...    --disco-show --include-type=WindowsHost
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label id="33333333-0000-0000-0000-000000000002" name="windows01.example.com" status="Available" type="WindowsHost"/> <label id="33333333-0000-0000-0000-000000000003" name="windows02.example.com" status="Unavailable" type="WindowsHost"/> </data>
