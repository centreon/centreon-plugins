*** Settings ***
Documentation       Database Mysql plugin

Library             OperatingSystem
Library             Process
Library             String

Test Timeout        120s


*** Variables ***
${CENTREON_PLUGINS}         ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl

${CMD}                      perl ${CENTREON_PLUGINS} --plugin=database::mysql::plugin

&{sql_string_test1}
...                         result=UNKNOWN: Need to specify data_source arguments.
@{sql_string_tests}
...                         &{sql_string_test1}


*** Test Cases ***
Database Mysql sql string mode
    [Documentation]    Mode sql string (common protocol database)
    [Tags]    database    mysql    sql-string
    FOR    ${sql_string_test}    IN    @{sql_string_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=sql-string
        ${output}    Run    ${command}
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${sql_string_test.result}
        ...    Wrong output result for compliance of ${sql_string_test.result}{\n}Command output:{\n}${output}{\n}{\n}{\n}
    END
