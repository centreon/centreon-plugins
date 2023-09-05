*** Settings ***
Documentation       OS Linux SNMP plugin

Library             OperatingSystem
Library             XML

Test Timeout        120s


*** Variables ***
${CENTREON_PLUGINS}         ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl

${CMD}                      perl ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin

&{list_diskio_test1}
...                         diskiodevice=
...                         name=
...                         regexp=
...                         nbresults=10
&{list_diskio_test2}
...                         diskiodevice=1
...                         name=
...                         regexp=
...                         nbresults=1
&{list_diskio_test3}
...                         diskiodevice=sda2
...                         name=true
...                         regexp=
...                         nbresults=1
&{list_diskio_test4}
...                         diskiodevice=sda
...                         name=true
...                         regexp=true
...                         nbresults=5
&{list_diskio_test5}
...                         diskiodevice=sda.*
...                         name=true
...                         regexp=true
...                         nbresults=5
&{list_diskio_test6}
...                         diskiodevice=sda1
...                         name=true
...                         regexp=true
...                         nbresults=2
&{list_diskio_test7}
...                         diskiodevice=SDA
...                         name=true
...                         regexp=true
...                         nbresults=0
@{list_diskio_tests}
...                         &{list_diskio_test1}
...                         &{list_diskio_test2}
...                         &{list_diskio_test3}
...                         &{list_diskio_test4}
...                         &{list_diskio_test5}
...                         &{list_diskio_test6}
...                         &{list_diskio_test7}


*** Test Cases ***
Linux SNMP list diskio devices
    [Documentation]    List Linux diskio devices
    [Tags]    os    linux    snmp
    FOR    ${list_diskio_test}    IN    @{list_diskio_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=list-diskio
        ...    --hostname=127.0.0.1
        ...    --snmp-version=2
        ...    --snmp-community=os_linux_snmp_plugin
        ...    --snmp-port=2024
        ...    --disco-show
        ${length}    Get Length    ${list_diskio_test.diskiodevice}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --diskiodevice=${list_diskio_test.diskiodevice}
        END
        ${length}    Get Length    ${list_diskio_test.name}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --name
        END
        ${length}    Get Length    ${list_diskio_test.regexp}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --regexp
        END
        ${output}    Run    ${command}
        Log To Console    ${command}
        ${nb_results}    Get Element Count
        ...    ${output}
        ...    label
        Should Be Equal As Integers
        ...    ${list_diskio_test.nbresults}
        ...    ${nb_results}
        ...    Wrong output result for list diskio devices: ${list_diskio_test}.{\n}Command output:{\n}${output}
    END
