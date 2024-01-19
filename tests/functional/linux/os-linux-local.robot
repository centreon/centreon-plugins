*** Settings ***
Documentation       Hardware UPS standard SNMP plugin

Library             OperatingSystem
Library             String

Test Timeout        120s


*** Variables ***
${CENTREON_PLUGINS}         ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl

${CMD}                      perl ${CENTREON_PLUGINS} --plugin=os::linux::local::plugin

# Test list-systemdcservices mode with filter-name option set to a fake value
&{linux_local_listsystemd_test1}
...                         filtername=toto
...                         filterdescription=
...                         result=List systemd services:

# Test list-systemdcservices mode with filter-name option set to a service name value
&{linux_local_listsystemd_test2}
...                         filtername=NetworkManager.service
...                         filterdescription=
...                         result=List systemd services: \n\'NetworkManager.service\' [desc = NetworkManager.service] [load = not-found] [active = inactive] [sub = dead]

# Test list-systemdcservices mode with filter-description option set to a fake value
&{linux_local_listsystemd_test3}
...                         filtername=
...                         filterdescription=toto
...                         result=List systemd services:

# Test list-systemdcservices mode with filter-description option set to a service description value
&{linux_local_listsystemd_test4}
...                         filtername=
...                         filterdescription='User Manager for UID 1001'
...                         result=List systemd services: \n\'user@1001.service\' [desc = User Manager for UID 1001] [load = loaded] [active = active] [sub = running]

@{linux_local_listsystemd_tests}
...                         &{linux_local_listsystemd_test1}
...                         &{linux_local_listsystemd_test2}
...                         &{linux_local_listsystemd_test3}
...                         &{linux_local_listsystemd_test4}

# Test simple usage of the systemdc-sc-status mode
&{linux_local_systemd_test_1}
...                         filtername=
...                         excludename=
...                         warningstatus=
...                         criticalstatus=
...                         warningtotalrunning=
...                         criticaltotalrunning=
...                         warningtotaldead=
...                         criticaltotaldead=
...                         warningtotalexited=
...                         criticaltotalexited=
...                         warningtotalfailed=
...                         criticaltotalfailed=
...                         result=OK: Total Running: 40, Total Failed: 0, Total Dead: 120, Total Exited: 40 - All services are ok | 'total_running'=40;;;0;414 'total_failed'=0;;;0;414 'total_dead'=120;;;0;414 'total_exited'=40;;;0;414

# Test systemdc-sc-status mode with filter-name option set to a fake value
&{linux_local_systemd_test_2}
...                         filtername=toto
...                         excludename=
...                         warningstatus=
...                         criticalstatus=
...                         warningtotalrunning=
...                         criticaltotalrunning=
...                         warningtotaldead=
...                         criticaltotaldead=
...                         warningtotalexited=
...                         criticaltotalexited=
...                         warningtotalfailed=
...                         criticaltotalfailed=
...                         result=UNKNOWN: No service found.

# Test systemdc-sc-status mode with filter-name option set to a service name value
&{linux_local_systemd_test_3}
...                         filtername=NetworkManager.service
...                         excludename=
...                         warningstatus=
...                         criticalstatus=
...                         warningtotalrunning=
...                         criticaltotalrunning=
...                         warningtotaldead=
...                         criticaltotaldead=
...                         warningtotalexited=
...                         criticaltotalexited=
...                         warningtotalfailed=
...                         criticaltotalfailed=
...                         result=OK: Total Running: 0, Total Failed: 0, Total Dead: 1, Total Exited: 0 - Service 'NetworkManager.service' status : not-found/inactive/dead [boot: not-found] | 'total_running'=0;;;0;1 'total_failed'=0;;;0;1 'total_dead'=1;;;0;1 'total_exited'=0;;;0;1

# Test systemdc-sc-status mode with exclude-name option set to a fake value
&{linux_local_systemd_test_4}
...                         filtername=
...                         excludename=toto
...                         warningstatus=
...                         criticalstatus=
...                         warningtotalrunning=
...                         criticaltotalrunning=
...                         warningtotaldead=
...                         criticaltotaldead=
...                         warningtotalexited=
...                         criticaltotalexited=
...                         warningtotalfailed=
...                         criticaltotalfailed=
...                         result=OK: Total Running: 40, Total Failed: 0, Total Dead: 120, Total Exited: 40 - All services are ok | 'total_running'=40;;;0;414 'total_failed'=0;;;0;414 'total_dead'=120;;;0;414 'total_exited'=40;;;0;414

# Test systemdc-sc-status mode with exclude-name option set to a service name value
&{linux_local_systemd_test_5}
...                         filtername=
...                         excludename=NetworkManager.service
...                         warningstatus=
...                         criticalstatus=
...                         warningtotalrunning=
...                         criticaltotalrunning=
...                         warningtotaldead=
...                         criticaltotaldead=
...                         warningtotalexited=
...                         criticaltotalexited=
...                         warningtotalfailed=
...                         criticaltotalfailed=
...                         result=OK: Total Running: 40, Total Failed: 0, Total Dead: 119, Total Exited: 40 - All services are ok | 'total_running'=40;;;0;413 'total_failed'=0;;;0;413 'total_dead'=119;;;0;413 'total_exited'=40;;;0;413

# Test systemdc-sc-status mode with warning-status option set to '%{boot} =~ /no-found/'
&{linux_local_systemd_test_6}
...                         filtername=
...                         excludename=
...                         warningstatus='%{boot} =~ /no-found/'
...                         criticalstatus=
...                         warningtotalrunning=
...                         criticaltotalrunning=
...                         warningtotaldead=
...                         criticaltotaldead=
...                         warningtotalexited=
...                         criticaltotalexited=
...                         warningtotalfailed=
...                         criticaltotalfailed=
...                         result=OK: Total Running: 40, Total Failed: 0, Total Dead: 119, Total Exited: 40 - All services are ok | 'total_running'=40;;;0;413 'total_failed'=0;;;0;413 'total_dead'=119;;;0;413 'total_exited'=40;;;0;413

@{linux_local_systemd_tests}
...                         &{linux_local_systemd_test_1}
...                         &{linux_local_systemd_test_2}
...                         &{linux_local_systemd_test_3}
...                         &{linux_local_systemd_test_4}
...                         &{linux_local_systemd_test_5}

*** Test Cases ***
Linux Local Systemd-sc-status
    [Documentation]    Linux Local Systemd services status
    [Tags]    os    linux    local
    FOR    ${linux_local_systemd_test}    IN    @{linux_local_systemd_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=systemd-sc-status
        ${length}    Get Length    ${linux_local_systemd_test.filtername}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --filter-name=${linux_local_systemd_test.filtername}
        END
        ${length}    Get Length    ${linux_local_systemd_test.excludename}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --exclude-name=${linux_local_systemd_test.excludename}
        END

        ${output}    Run    ${command}
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${linux_local_systemd_test.result}
        ...    Wrong result output for:${\n}Command: ${\n}${command}${\n}${\n}Expected output: ${\n}${linux_local_systemd_test.result}${\n}${\n}Obtained output:${\n}${output}${\n}${\n}${\n}
        ...    values=False
    END

Linux Local List-systemd-services
    [Documentation]    Linux Local List Systemd services
    [Tags]    os    linux    local
    FOR    ${linux_local_listsystemd_test}    IN    @{linux_local_listsystemd_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=list-systemdservices
        ${length}    Get Length    ${linux_local_listsystemd_test.filtername}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --filter-name=${linux_local_listsystemd_test.filtername}
        END
        ${length}    Get Length    ${linux_local_listsystemd_test.filterdescription}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --filter-description=${linux_local_listsystemd_test.filterdescription}
        END

        ${output}    Run    ${command}
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${linux_local_listsystemd_test.result}
        ...    Wrong result output for:${\n}Command: ${\n}${command}${\n}${\n}Expected output: ${\n}${linux_local_listsystemd_test.result}${\n}${\n}Obtained output:${\n}${output}${\n}${\n}${\n}
        ...    values=False
    END