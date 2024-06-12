*** Settings ***
Documentation       OS Linux SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                  ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin

&{list_diskio_test1}
...                     snmpcommunity=os/linux/snmp/list-diskio
...                     nbresults=10
&{list_diskio_test2}
...                     snmpcommunity=os/linux/snmp/list-diskio-2
...                     nbresults=4
@{list_diskio_tests}
...                     &{list_diskio_test1}
...                     &{list_diskio_test2}


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
        ...    --snmp-port=2024
        ...    --disco-show
        ...    --snmp-community=${list_diskio_test.snmpcommunity}
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
