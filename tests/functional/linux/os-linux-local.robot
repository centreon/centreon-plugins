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

# Test systemdc-sc-status mode with warning-status option set to '%{sub} =~ /exited/'
&{linux_local_systemd_test_6}
...                         filtername=
...                         excludename=
...                         warningstatus='\%{sub} =~ /exited/'
...                         criticalstatus=
...                         warningtotalrunning=
...                         criticaltotalrunning=
...                         warningtotaldead=
...                         criticaltotaldead=
...                         warningtotalexited=
...                         criticaltotalexited=
...                         warningtotalfailed=
...                         criticaltotalfailed=
...                         result=WARNING: Service 'apparmor.service' status : loaded/active/exited [boot: loaded] - Service 'apport.service' status : loaded/active/exited [boot: loaded] - Service 'binfmt-support.service' status : loaded/active/exited [boot: loaded] - Service 'blk-availability.service' status : loaded/active/exited [boot: loaded] - Service 'cloud-config.service' status : loaded/active/exited [boot: loaded] - Service 'cloud-final.service' status : loaded/active/exited [boot: loaded] - Service 'cloud-init-local.service' status : loaded/active/exited [boot: loaded] - Service 'cloud-init.service' status : loaded/active/exited [boot: loaded] - Service 'console-setup.service' status : loaded/active/exited [boot: loaded] - Service 'ephemeral-disk-warning.service' status : loaded/active/exited [boot: loaded] - Service 'finalrd.service' status : loaded/active/exited [boot: loaded] - Service 'keyboard-setup.service' status : loaded/active/exited [boot: loaded] - Service 'kmod-static-nodes.service' status : loaded/active/exited [boot: loaded] - Service 'lvm2-monitor.service' status : loaded/active/exited [boot: loaded] - Service 'plymouth-quit-wait.service' status : loaded/active/exited [boot: loaded] - Service 'plymouth-quit.service' status : loaded/active/exited [boot: loaded] - Service 'plymouth-read-write.service' status : loaded/active/exited [boot: loaded] - Service 'podman-restart.service' status : loaded/active/exited [boot: loaded] - Service 'setvtrgb.service' status : loaded/active/exited [boot: loaded] - Service 'snapd.apparmor.service' status : loaded/active/exited [boot: loaded] - Service 'snapd.seeded.service' status : loaded/active/exited [boot: loaded] - Service 'sphinxsearch.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-binfmt.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-fsck-root.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-fsck@dev-disk-by\x2duuid-8C08\x2d0632.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-journal-flush.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-modules-load.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-networkd-wait-online.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-random-seed.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-remount-fs.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-sysctl.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-sysusers.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-tmpfiles-setup-dev.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-tmpfiles-setup.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-udev-trigger.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-update-utmp.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-user-sessions.service' status : loaded/active/exited [boot: loaded] - Service 'ufw.service' status : loaded/active/exited [boot: loaded] - Service 'user-runtime-dir@1001.service' status : loaded/active/exited [boot: loaded] - Service 'walinuxagent-network-setup.service' status : loaded/active/exited [boot: loaded] | 'total_running'=40;;;0;414 'total_failed'=0;;;0;414 'total_dead'=120;;;0;414 'total_exited'=40;;;0;414

# Test systemdc-sc-status mode with critical-status option set to '%{sub} =~ /exited/'
&{linux_local_systemd_test_7}
...                         filtername=
...                         excludename=
...                         warningstatus=
...                         criticalstatus='\%{sub} =~ /exited/'
...                         warningtotalrunning=
...                         criticaltotalrunning=
...                         warningtotaldead=
...                         criticaltotaldead=
...                         warningtotalexited=
...                         criticaltotalexited=
...                         warningtotalfailed=
...                         criticaltotalfailed=
...                         result=CRITICAL: Service 'apparmor.service' status : loaded/active/exited [boot: loaded] - Service 'apport.service' status : loaded/active/exited [boot: loaded] - Service 'binfmt-support.service' status : loaded/active/exited [boot: loaded] - Service 'blk-availability.service' status : loaded/active/exited [boot: loaded] - Service 'cloud-config.service' status : loaded/active/exited [boot: loaded] - Service 'cloud-final.service' status : loaded/active/exited [boot: loaded] - Service 'cloud-init-local.service' status : loaded/active/exited [boot: loaded] - Service 'cloud-init.service' status : loaded/active/exited [boot: loaded] - Service 'console-setup.service' status : loaded/active/exited [boot: loaded] - Service 'ephemeral-disk-warning.service' status : loaded/active/exited [boot: loaded] - Service 'finalrd.service' status : loaded/active/exited [boot: loaded] - Service 'keyboard-setup.service' status : loaded/active/exited [boot: loaded] - Service 'kmod-static-nodes.service' status : loaded/active/exited [boot: loaded] - Service 'lvm2-monitor.service' status : loaded/active/exited [boot: loaded] - Service 'plymouth-quit-wait.service' status : loaded/active/exited [boot: loaded] - Service 'plymouth-quit.service' status : loaded/active/exited [boot: loaded] - Service 'plymouth-read-write.service' status : loaded/active/exited [boot: loaded] - Service 'podman-restart.service' status : loaded/active/exited [boot: loaded] - Service 'setvtrgb.service' status : loaded/active/exited [boot: loaded] - Service 'snapd.apparmor.service' status : loaded/active/exited [boot: loaded] - Service 'snapd.seeded.service' status : loaded/active/exited [boot: loaded] - Service 'sphinxsearch.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-binfmt.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-fsck-root.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-fsck@dev-disk-by\x2duuid-8C08\x2d0632.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-journal-flush.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-modules-load.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-networkd-wait-online.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-random-seed.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-remount-fs.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-sysctl.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-sysusers.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-tmpfiles-setup-dev.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-tmpfiles-setup.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-udev-trigger.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-update-utmp.service' status : loaded/active/exited [boot: loaded] - Service 'systemd-user-sessions.service' status : loaded/active/exited [boot: loaded] - Service 'ufw.service' status : loaded/active/exited [boot: loaded] - Service 'user-runtime-dir@1001.service' status : loaded/active/exited [boot: loaded] - Service 'walinuxagent-network-setup.service' status : loaded/active/exited [boot: loaded] | 'total_running'=40;;;0;414 'total_failed'=0;;;0;414 'total_dead'=120;;;0;414 'total_exited'=40;;;0;414

@{linux_local_systemd_tests}
...                         &{linux_local_systemd_test_1}
...                         &{linux_local_systemd_test_2}
...                         &{linux_local_systemd_test_3}
...                         &{linux_local_systemd_test_4}
...                         &{linux_local_systemd_test_5}
...                         &{linux_local_systemd_test_6}
...                         &{linux_local_systemd_test_7}

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

        ${output}    Run    ${command}
        Log To Console    .    no_newline=true
        Log To Console    ${output}
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