*** Settings ***
Documentation       Database Mysql plugin

Resource            ${CURDIR}${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                  ${CENTREON_PLUGINS} --plugin=database::mysql::plugin

*** Test Cases ***
Database Mysql sql string mode ${tc}
    [Documentation]    Mode sql string (common protocol database)
    [Tags]    database    mysql    sql-string
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=sql-string
    
    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:         tc  expected_result    --
            ...       1   UNKNOWN: Need to specify data_source arguments.
