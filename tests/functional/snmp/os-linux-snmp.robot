*** Settings ***
Documentation       OS Linux SNMP plugin

Library             OperatingSystem
Library             XML


*** Variables ***
${CENTREON_PLUGINS}     ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl

${CMD}                  perl ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin

&{list_diskio_test1}
...                     diskiodevice=
...                     name=
...                     regexp=
...                     regexp_isensitive=
...                     display_transform_src=
...                     display_transform_dst=
...                     nbresults=10
&{list_diskio_test2}
...                     diskiodevice=1
...                     name=
...                     regexp=
...                     regexp_isensitive=
...                     display_transform_src=
...                     display_transform_dst=
...                     nbresults=1
&{list_diskio_test3}
...                     diskiodevice=sda2
...                     name=true
...                     regexp=
...                     regexp_isensitive=
...                     display_transform_src=
...                     display_transform_dst=
...                     nbresults=1
&{list_diskio_test4}
...                     diskiodevice=sda
...                     name=true
...                     regexp=true
...                     regexp_isensitive=
...                     display_transform_src=
...                     display_transform_dst=
...                     nbresults=5
&{list_diskio_test5}
...                     diskiodevice=sda.*
...                     name=true
...                     regexp=true
...                     regexp_isensitive=
...                     display_transform_src=
...                     display_transform_dst=
...                     nbresults=5
&{list_diskio_test6}
...                     diskiodevice=sda1
...                     name=true
...                     regexp=true
...                     regexp_isensitive=
...                     display_transform_src=
...                     display_transform_dst=
...                     nbresults=2
&{list_diskio_test7}
...                     diskiodevice=SDA
...                     name=true
...                     regexp=true
...                     regexp_isensitive=
...                     display_transform_src=
...                     display_transform_dst=
...                     nbresults=0
&{list_diskio_test8}
...                     diskiodevice=LOOP
...                     name=true
...                     regexp=true
...                     regexp_isensitive=true
...                     display_transform_src=
...                     display_transform_dst=
...                     nbresults=2
&{list_diskio_test9}
...                     diskiodevice=loop
...                     name=true
...                     regexp=true
...                     regexp_isensitive=true
...                     display_transform_src=
...                     display_transform_dst=
...                     nbresults=2
&{list_diskio_test8}
...                     diskiodevice=SDA
...                     name=true
...                     regexp=true
...                     regexp_isensitive=true
...                     display_transform_src=
...                     display_transform_dst=
...                     nbresults=5
&{list_diskio_test9}
...                     diskiodevice=sda
...                     name=true
...                     regexp=true
...                     regexp_isensitive=true
...                     display_transform_src=
...                     display_transform_dst=
...                     nbresults=5
@{list_diskio_tests}
...                     &{list_diskio_test1}
...                     &{list_diskio_test2}
...                     &{list_diskio_test3}
...                     &{list_diskio_test4}
...                     &{list_diskio_test5}
...                     &{list_diskio_test6}
...                     &{list_diskio_test7}
...                     &{list_diskio_test8}
...                     &{list_diskio_test9}


*** Test Cases ***
Linux SNMP list diskio devices
    [Documentation]    List Linux diskio devices
    [Tags]    os    linux    snmp
    FOR    ${list_diskio_test}    IN    @{list_diskio_tests}
        ${command} =    Catenate
        ...    ${CMD}
        ...    --mode=list-diskio
        ...    --hostname=127.0.0.1
        ...    --snmp-version=2
        ...    --snmp-community=os_linux_snmp_plugin
        ...    --snmp-port=2024
        ...    --disco-show
        ${length} =    Get Length    ${list_diskio_test.diskiodevice}
        IF    ${length} > 0
            ${command} =    Catenate    ${command}    --diskiodevice=${list_diskio_test.diskiodevice}
        END
        ${length} =    Get Length    ${list_diskio_test.name}
        IF    ${length} > 0
            ${command} =    Catenate    ${command}    --name
        END
        ${length} =    Get Length    ${list_diskio_test.regexp}
        IF    ${length} > 0
            ${command} =    Catenate    ${command}    --regexp
        END
        ${length} =    Get Length    ${list_diskio_test.regexp_isensitive}
        IF    ${length} > 0
            ${command} =    Catenate    ${command}    --regexp-isensitive
        END
        ${length} =    Get Length    ${list_diskio_test.display_transform_src}
        IF    ${length} > 0
            ${command} =    Catenate    ${command}    --display-transform-src=${list_diskio_test.display_transform_src}
        END
        ${length} =    Get Length    ${list_diskio_test.display_transform_dst}
        IF    ${length} > 0
            ${command} =    Catenate    ${command}    --display-transform-dst=${list_diskio_test.display_transform_dst}
        END
        ${output} =    Run    ${command}
        ${nb_results} =    Get Element Count
        ...    ${output}
        ...    label
        Should Be Equal As Integers
        ...    ${list_diskio_test.nbresults}
        ...    ${nb_results}
        ...    msg=Wrong output result for list diskio devices: ${list_diskio_test}
    END
