*** Settings ***
Documentation       Keysight Nvos Restapi plugin

Library             OperatingSystem
Library             Process
Library             String

Suite Setup         Start Mockoon
Suite Teardown      Stop Mockoon
Test Timeout        120s

*** Variables ***
${CENTREON_PLUGINS}             ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl
${MOCKOON_JSON}                 ${CURDIR}${/}..${/}..${/}resources${/}mockoon${/}keysight-nvos-restapi.json

${CMD}                          perl ${CENTREON_PLUGINS} --plugin=network::keysight::nvos::restapi::plugin --custommode=paws --region=eu-west --aws-secret-key=secret --aws-access-key=key

# Test simple usage of the ports mode
&{keysight_ports_test1}
...                             filtername=
...                             filtertype=
...                             unknownlicensestatus=
...                             warninglicensestatus=
...                             criticallicensestatus=
...                             unknownlinkstatus=
...                             warninglinkstatus=
...                             criticallinkstatus=
...                             warningtrafficoutprct=
...                             criticaltrafficoutprct=
...                             warningtrafficout=
...                             criticaltrafficout=
...                             warningpacketsout=
...                             criticalpacketsout=
...                             warningpacketsdropped=
...                             criticalpacketsdropped=
...                             warningpacketspass=
...                             criticalpacketspass=
...                             warningpacketsinsp=
...                             criticalpacketsinsp=
...                             result=

@{keysight_ports_tests}

# Test simple usage of the license mode
&{keysight_license_test1}
...                             unknownstatus=
...                             warningstatus=
...                             criticalstatus=
...                             result=OK: License expiration status: NONE\nExpired: Maintenance; Oct 20, 2023 23:59:59 GMT

# Test license mode with unknown-status option set to '%{status} =~ /NONE/i'
&{keysight_license_test2}
...                             unknownstatus='\%{status} =~ /NONE/i'
...                             warningstatus=
...                             criticalstatus=
...                             result=UNKNOWN: License expiration status: NONE\nExpired: Maintenance; Oct 20, 2023 23:59:59 GMT

# Test license mode with warning-status option set to '%{status} =~ /NONE/i'
&{keysight_license_test3}
...                             unknownstatus=
...                             warningstatus='\%{status} =~ /NONE/i'
...                             criticalstatus=
...                             result=WARNING: License expiration status: NONE\nExpired: Maintenance; Oct 20, 2023 23:59:59 GMT

# Test license mode with critical-status option set to '%{status} =~ /NONE/i'
&{keysight_license_test4}
...                             unknownstatus=
...                             warningstatus=
...                             criticalstatus='\%{status} =~ /NONE/i'
...                             result=CRITICAL: License expiration status: NONE\nExpired: Maintenance; Oct 20, 2023 23:59:59 GMT

@{keysight_license_tests}
...                             &{keysight_license_test1}
...                             &{keysight_license_test2}
...                             &{keysight_license_test3}
...                             &{keysight_license_test4}

*** Test Cases ***
Keysight Nvos Restapi ports
    [Documentation]    Keysight Nvos Restapi ports
    [Tags]    keysight    nvos    restapi
    FOR    ${keysight_ports_test}    IN    @{keysight_ports_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=ports
        ...    --hostname=localhost
        ...    --port=3003
        ...    --api-username='admin'
        ...    --api-password='admin'
        ...    --proto='http'
        ${length}    Get Length    ${keysight_ports_test.filtername}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --filter-name=${keysight_ports_test.filtername}
        END
        ${length}    Get Length    ${keysight_ports_test.filtertype}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --filter-type=${keysight_ports_test.filtertype}
        END
        ${output}    Run    ${command}
        Log To Console    .    no_newline=true
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${keysight_ports_test.result}
        ...    Wrong result output for:${\n}Command: ${\n}${command}${\n}${\n}Expected output: ${\n}${keysight_ports_test.result}${\n}${\n}Obtained output:${\n}${output}${\n}${\n}${\n}
        ...    values=False
    END

Keysight Nvos Restapi license
    [Documentation]    Keysight Nvos Restapi license
    [Tags]    keysight    nvos    restapi
    FOR    ${keysight_license_test}    IN    @{keysight_license_tests}
                ${command}    Catenate
        ...    ${CMD}
        ...    --mode=ports
        ...    --hostname=localhost
        ...    --port=3003
        ...    --api-username='admin'
        ...    --api-password='admin'
        ...    --proto='http'
        ${length}    Get Length    ${keysight_license_test.unknownstatus}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --unknown-status=${keysight_license_test.unknownstatus}
        END
        ${length}    Get Length    ${keysight_license_test.warningstatus}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --warning-status=${keysight_license_test.warningstatus}
        END
        ${length}    Get Length    ${keysight_license_test.criticalstatus}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --critical-status=${keysight_license_test.criticalstatus}
        END
        ${output}    Run    ${command}
        Log To Console    .    no_newline=true
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${keysight_license_test.result}
        ...    Wrong result output for:${\n}Command: ${\n}${command}${\n}${\n}Expected output: ${\n}${keysight_license_test.result}${\n}${\n}Obtained output:${\n}${output}${\n}${\n}${\n}
        ...    values=False
    END


*** Keywords ***
Start Mockoon
    ${process}    Start Process
    ...    mockoon-cli
    ...    start
    ...    --data
    ...    ${MOCKOON_JSON}
    ...    --port
    ...    3003
    ...    --pname
    ...    keysight-nvos
    Wait For Process    ${process}

Stop Mockoon
    ${process}    Start Process
    ...    mockoon-cli
    ...    stop
    ...    mockoon-keysight-nvos
    Wait For Process    ${process}

