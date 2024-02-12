*** Settings ***
Documentation       OS Linux Local plugin

Library             OperatingSystem
Library             String

Test Timeout        120s


*** Variables ***
${CENTREON_PLUGINS}                 ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl

${CMD}                              perl ${CENTREON_PLUGINS} --plugin=os::linux::local::plugin

# Test list-systemdservices mode with filter-name option set to a fake value
&{linux_local_listsystemd_test1}
...                                 filtername=toto
...                                 filterdescription=
...                                 result=List systemd services:

# Test list-systemdservices mode with filter-name option set to a service name value
&{linux_local_listsystemd_test2}
...                                 filtername=NetworkManager.service
...                                 filterdescription=
...                                 result=List systemd services: \n\'NetworkManager.service\' [desc = NetworkManager.service] [load = not-found] [active = inactive] [sub = dead]

# Test list-systemdservices mode with filter-description option set to a fake value
&{linux_local_listsystemd_test3}
...                                 filtername=
...                                 filterdescription=toto
...                                 result=List systemd services:

# Test list-systemdservices mode with filter-description option set to a service description value
&{linux_local_listsystemd_test4}
...                                 filtername=
...                                 filterdescription='User Manager for UID 1001'
...                                 result=List systemd services: \n\'user@1001.service\' [desc = User Manager for UID 1001] [load = loaded] [active = active] [sub = running]

@{linux_local_listsystemd_tests}
...                                 &{linux_local_listsystemd_test1}
...                                 &{linux_local_listsystemd_test2}
...                                 &{linux_local_listsystemd_test3}
...                                 &{linux_local_listsystemd_test4}

# Test simple usage of the systemd-sc-status mode
&{linux_local_systemd_test_1}
...                                 filtername=
...                                 excludename=
...                                 warningstatus=
...                                 criticalstatus=
...                                 warningtotalrunning=
...                                 criticaltotalrunning=
...                                 warningtotaldead=
...                                 criticaltotaldead=
...                                 warningtotalexited=
...                                 criticaltotalexited=
...                                 warningtotalfailed=
...                                 criticaltotalfailed=
...                                 result=OK: Total Running: 40, Total Failed: 0, Total Dead: 120, Total Exited: 40 - All services are ok | 'total_running'=40;;;0;414 'total_failed'=0;;;0;414 'total_dead'=120;;;0;414 'total_exited'=40;;;0;414

# Test systemd-sc-status mode with filter-name option set to a fake value
&{linux_local_systemd_test_2}
...                                 filtername=toto
...                                 excludename=
...                                 warningstatus=
...                                 criticalstatus=
...                                 warningtotalrunning=
...                                 criticaltotalrunning=
...                                 warningtotaldead=
...                                 criticaltotaldead=
...                                 warningtotalexited=
...                                 criticaltotalexited=
...                                 warningtotalfailed=
...                                 criticaltotalfailed=
...                                 result=UNKNOWN: No service found.

# Test systemd-sc-status mode with filter-name option set to a service name value
&{linux_local_systemd_test_3}
...                                 filtername=NetworkManager.service
...                                 excludename=
...                                 warningstatus=
...                                 criticalstatus=
...                                 warningtotalrunning=
...                                 criticaltotalrunning=
...                                 warningtotaldead=
...                                 criticaltotaldead=
...                                 warningtotalexited=
...                                 criticaltotalexited=
...                                 warningtotalfailed=
...                                 criticaltotalfailed=
...                                 result=OK: Total Running: 0, Total Failed: 0, Total Dead: 1, Total Exited: 0 - Service 'NetworkManager.service' status : not-found/inactive/dead [boot: -] | 'total_running'=0;;;0;1 'total_failed'=0;;;0;1 'total_dead'=1;;;0;1 'total_exited'=0;;;0;1

# Test systemd-sc-status mode with exclude-name option set to a fake value
&{linux_local_systemd_test_4}
...                                 filtername=
...                                 excludename=toto
...                                 warningstatus=
...                                 criticalstatus=
...                                 warningtotalrunning=
...                                 criticaltotalrunning=
...                                 warningtotaldead=
...                                 criticaltotaldead=
...                                 warningtotalexited=
...                                 criticaltotalexited=
...                                 warningtotalfailed=
...                                 criticaltotalfailed=
...                                 result=OK: Total Running: 40, Total Failed: 0, Total Dead: 120, Total Exited: 40 - All services are ok | 'total_running'=40;;;0;414 'total_failed'=0;;;0;414 'total_dead'=120;;;0;414 'total_exited'=40;;;0;414

# Test systemd-sc-status mode with exclude-name option set to a service name value
&{linux_local_systemd_test_5}
...                                 filtername=
...                                 excludename=NetworkManager.service
...                                 warningstatus=
...                                 criticalstatus=
...                                 warningtotalrunning=
...                                 criticaltotalrunning=
...                                 warningtotaldead=
...                                 criticaltotaldead=
...                                 warningtotalexited=
...                                 criticaltotalexited=
...                                 warningtotalfailed=
...                                 criticaltotalfailed=
...                                 result=OK: Total Running: 40, Total Failed: 0, Total Dead: 119, Total Exited: 40 - All services are ok | 'total_running'=40;;;0;413 'total_failed'=0;;;0;413 'total_dead'=119;;;0;413 'total_exited'=40;;;0;413

# Test systemd-sc-status mode with warning-status option set to '\%{sub} =~ /exited/ && \%{display} =~ /network/'
&{linux_local_systemd_test_6}
...                                 filtername=
...                                 excludename=
...                                 warningstatus='\%{sub} =~ /exited/ && \%{display} =~ /network/'
...                                 criticalstatus=
...                                 warningtotalrunning=
...                                 criticaltotalrunning=
...                                 warningtotaldead=
...                                 criticaltotaldead=
...                                 warningtotalexited=
...                                 criticaltotalexited=
...                                 warningtotalfailed=
...                                 criticaltotalfailed=
...                                 result=WARNING: Service 'systemd-networkd-wait-online.service' status : loaded/active/exited [boot: enabled] - Service 'walinuxagent-network-setup.service' status : loaded/active/exited [boot: enabled] | 'total_running'=40;;;0;414 'total_failed'=0;;;0;414 'total_dead'=120;;;0;414 'total_exited'=40;;;0;414

# Test systemd-sc-status mode with critical-status option set to '\%{sub} =~ /exited/ && \%{display} =~ /network/'
&{linux_local_systemd_test_7}
...                                 filtername=
...                                 excludename=
...                                 warningstatus=
...                                 criticalstatus='\%{sub} =~ /exited/ && \%{display} =~ /network/'
...                                 warningtotalrunning=
...                                 criticaltotalrunning=
...                                 warningtotaldead=
...                                 criticaltotaldead=
...                                 warningtotalexited=
...                                 criticaltotalexited=
...                                 warningtotalfailed=
...                                 criticaltotalfailed=
...                                 result=CRITICAL: Service 'systemd-networkd-wait-online.service' status : loaded/active/exited [boot: enabled] - Service 'walinuxagent-network-setup.service' status : loaded/active/exited [boot: enabled] | 'total_running'=40;;;0;414 'total_failed'=0;;;0;414 'total_dead'=120;;;0;414 'total_exited'=40;;;0;414

# Test systemd-sc-status mode with warning-total-running option set to 20
&{linux_local_systemd_test_8}
...                                 filtername=
...                                 excludename=
...                                 warningstatus=
...                                 criticalstatus=
...                                 warningtotalrunning=20
...                                 criticaltotalrunning=
...                                 warningtotaldead=
...                                 criticaltotaldead=
...                                 warningtotalexited=
...                                 criticaltotalexited=
...                                 warningtotalfailed=
...                                 criticaltotalfailed=
...                                 result=WARNING: Total Running: 40 | 'total_running'=40;0:20;;0;414 'total_failed'=0;;;0;414 'total_dead'=120;;;0;414 'total_exited'=40;;;0;414

# Test systemd-sc-status mode with critical-total-running option set to 20
&{linux_local_systemd_test_9}
...                                 filtername=
...                                 excludename=
...                                 warningstatus=
...                                 criticalstatus=
...                                 warningtotalrunning=
...                                 criticaltotalrunning=20
...                                 warningtotaldead=
...                                 criticaltotaldead=
...                                 warningtotalexited=
...                                 criticaltotalexited=
...                                 warningtotalfailed=
...                                 criticaltotalfailed=
...                                 result=CRITICAL: Total Running: 40 | 'total_running'=40;;0:20;0;414 'total_failed'=0;;;0;414 'total_dead'=120;;;0;414 'total_exited'=40;;;0;414

# Test systemd-sc-status mode with warning-total-dead option set to 20
&{linux_local_systemd_test_10}
...                                 filtername=
...                                 excludename=
...                                 warningstatus=
...                                 criticalstatus=
...                                 warningtotalrunning=
...                                 criticaltotalrunning=
...                                 warningtotaldead=20
...                                 criticaltotaldead=
...                                 warningtotalexited=
...                                 criticaltotalexited=
...                                 warningtotalfailed=
...                                 criticaltotalfailed=
...                                 result=WARNING: Total Dead: 120 | 'total_running'=40;;;0;414 'total_failed'=0;;;0;414 'total_dead'=120;0:20;;0;414 'total_exited'=40;;;0;414

# Test systemd-sc-status mode with critical-total-dead option set to 20
&{linux_local_systemd_test_11}
...                                 filtername=
...                                 excludename=
...                                 warningstatus=
...                                 criticalstatus=
...                                 warningtotalrunning=
...                                 criticaltotalrunning=
...                                 warningtotaldead=
...                                 criticaltotaldead=20
...                                 warningtotalexited=
...                                 criticaltotalexited=
...                                 warningtotalfailed=
...                                 criticaltotalfailed=
...                                 result=CRITICAL: Total Dead: 120 | 'total_running'=40;;;0;414 'total_failed'=0;;;0;414 'total_dead'=120;;0:20;0;414 'total_exited'=40;;;0;414

# Test systemd-sc-status mode with warning-total-exited option set to 20
&{linux_local_systemd_test_12}
...                                 filtername=
...                                 excludename=
...                                 warningstatus=
...                                 criticalstatus=
...                                 warningtotalrunning=
...                                 criticaltotalrunning=
...                                 warningtotaldead=
...                                 criticaltotaldead=
...                                 warningtotalexited=20
...                                 criticaltotalexited=
...                                 warningtotalfailed=
...                                 criticaltotalfailed=
...                                 result=WARNING: Total Exited: 40 | 'total_running'=40;;;0;414 'total_failed'=0;;;0;414 'total_dead'=120;;;0;414 'total_exited'=40;0:20;;0;414

# Test systemd-sc-status mode with critical-total-exited option set to 20
&{linux_local_systemd_test_13}
...                                 filtername=
...                                 excludename=
...                                 warningstatus=
...                                 criticalstatus=
...                                 warningtotalrunning=
...                                 criticaltotalrunning=
...                                 warningtotaldead=
...                                 criticaltotaldead=
...                                 warningtotalexited=
...                                 criticaltotalexited=20
...                                 warningtotalfailed=
...                                 criticaltotalfailed=
...                                 result=CRITICAL: Total Exited: 40 | 'total_running'=40;;;0;414 'total_failed'=0;;;0;414 'total_dead'=120;;;0;414 'total_exited'=40;;0:20;0;414

# Test systemd-sc-status mode with warning-total-failed option : NO DATA FOR THIS TEST

# Test systemd-sc-status mode with critical-total-failed option : NO DATA FOR THIS TEST

@{linux_local_systemd_tests}
...                                 &{linux_local_systemd_test_1}
...                                 &{linux_local_systemd_test_2}
...                                 &{linux_local_systemd_test_3}
...                                 &{linux_local_systemd_test_4}
...                                 &{linux_local_systemd_test_5}
...                                 &{linux_local_systemd_test_6}
...                                 &{linux_local_systemd_test_7}
...                                 &{linux_local_systemd_test_8}
...                                 &{linux_local_systemd_test_9}
...                                 &{linux_local_systemd_test_10}
...                                 &{linux_local_systemd_test_11}
...                                 &{linux_local_systemd_test_12}
...                                 &{linux_local_systemd_test_13}


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
        ${length}    Get Length    ${linux_local_systemd_test.warningstatus}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --warning-status=${linux_local_systemd_test.warningstatus}
        END
        ${length}    Get Length    ${linux_local_systemd_test.criticalstatus}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --critical-status=${linux_local_systemd_test.criticalstatus}
        END
        ${length}    Get Length    ${linux_local_systemd_test.warningtotalrunning}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --warning-total-running=${linux_local_systemd_test.warningtotalrunning}
        END
        ${length}    Get Length    ${linux_local_systemd_test.criticaltotalrunning}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --critical-total-running=${linux_local_systemd_test.criticaltotalrunning}
        END
        ${length}    Get Length    ${linux_local_systemd_test.warningtotaldead}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --warning-total-dead=${linux_local_systemd_test.warningtotaldead}
        END
        ${length}    Get Length    ${linux_local_systemd_test.criticaltotaldead}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --critical-total-dead=${linux_local_systemd_test.criticaltotaldead}
        END
        ${length}    Get Length    ${linux_local_systemd_test.warningtotalexited}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --warning-total-exited=${linux_local_systemd_test.warningtotalexited}
        END
        ${length}    Get Length    ${linux_local_systemd_test.criticaltotalexited}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --critical-total-exited=${linux_local_systemd_test.criticaltotalexited}
        END
        ${length}    Get Length    ${linux_local_systemd_test.warningtotalfailed}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --warning-total-failed=${linux_local_systemd_test.warningtotalfailed}
        END
        ${length}    Get Length    ${linux_local_systemd_test.criticaltotalfailed}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --critical-total-failed=${linux_local_systemd_test.criticaltotalfailed}
        END

        ${output}    Run    ${command}
        Log To Console    .    no_newline=true
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
            ${command}    Catenate
            ...    ${command}
            ...    --filter-description=${linux_local_listsystemd_test.filterdescription}
        END

        ${output}    Run    ${command}
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${linux_local_listsystemd_test.result}
        ...    Wrong result output for:${\n}Command: ${\n}${command}${\n}${\n}Expected output: ${\n}${linux_local_listsystemd_test.result}${\n}${\n}Obtained output:${\n}${output}${\n}${\n}${\n}
        ...    values=False
    END
