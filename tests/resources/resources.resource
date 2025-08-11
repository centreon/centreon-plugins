*** Settings ***
Documentation       Centreon Plugins for Robot Framework

Library             Process

*** Variables ***
${CENTREON_PLUGINS}     perl ${CURDIR}${/}..${/}..${/}src${/}centreon_plugins.pl
# one we use package, we need to remove the "perl" part to be sure the plugin is executable and is correctly formated
# with a shebang at the top.
${HOSTNAME}             127.0.0.1
${APIPORT}              3000
${SNMPPORT}             2024
${SNMPVERSION}          2c
${PERCENT}              %
${MOCKOON_LOG_FILE}    /tmp/mockoon.log
${TIMEOUT}             30

*** Keywords ***
Start Mockoon
    [Arguments]    ${MOCKOON_JSON}
    Ctn Generic Suite Setup
    Remove File    ${MOCKOON_LOG_FILE}

    ${time_start}    Get Time    str=epoch

    ${process}    Start Process
    ...    mockoon-cli
    ...    start
    ...    --data
    ...    ${MOCKOON_JSON}
    ...    --port
    ...    3000
    ...    stdout=${MOCKOON_LOG_FILE}

    Wait Until Created    ${MOCKOON_LOG_FILE}
    Wait Until Keyword Succeeds
    ...     30
    ...     1
    ...     File Should Not Be Empty	${MOCKOON_LOG_FILE}

    ${time_end}    Get Time    str=epoch
    ${duration} =     Evaluate    ${time_end} - ${time_start}
    Log To Console    Mockoon finished starting after ${duration} seconds

Stop Mockoon
    Terminate All Processes
    Remove File    ${MOCKOON_LOG_FILE}
    Ctn Generic Suite Teardown

Ctn Cleanup Cache
    Remove File    ${/}var${/}lib${/}centreon${/}centplugins${/}*
    Remove File    ${/}dev${/}shm${/}*

Ctn Generic Suite Setup
   Ctn Cleanup Cache
   Set Environment Variable    TZ    UTC
   Ctn Clear Connector Log
   Remove Files    /tmp/connector.output*
   Remove File    /tmp/connector.log
   Ctn Start Connector

Ctn Generic Suite Teardown
    Ctn Stop Connector

Ctn Clear Connector Log
    [Documentation]    Safely empties the connector log file without deleting it
    Create File    /tmp/connector.log

Ctn Stop Connector
   Terminate All Processes
   Ctn Kill Connector
   Remove Files    /tmp/connector.output*
   Remove File     /tmp/connector.log

Ctn Run Command Without Connector And Check Result As Regexp
    [Arguments]    ${command}    ${expected_result}
    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Match Regexp
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected regular expression:\n${expected_result}\n
    ...    values=False

Ctn Run Command Without Connector And Check Result As Strings
    [Arguments]    ${command}    ${expected_result}
    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${expected_result}
    ...    ${output}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True

Ctn Verify Command Without Connector Output
    [Arguments]    ${command}    ${expected_result}
    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Contain    
    ...    ${output}    
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True

Ctn Run Command With Connector And Check Result As Strings
    [Arguments]    ${command}    ${expected_result}    ${tc}=0    ${timeout}=${TIMEOUT}
    Remove File    /tmp/connector.output
    Remove File    /tmp/connector.command.log
    Ctn Send To Connector    ${tc}    ${command}    ${timeout}
    # 1. Extract the result from the log and write to /tmp/connector.output
    Ctn Extract Result From Log    ${tc}
    # 2. Read the file
    ${output}    Get File    /tmp/connector.output
    ${output}    Strip String    ${output}
    # 3. Compare with expected
    Should Be Equal As Strings
    ...    ${expected_result}
    ...    ${output}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True


Ctn Run Command With Connector And Check Result As Regexp
    [Arguments]    ${command}    ${expected_result}    ${tc}=0    ${timeout}=${TIMEOUT}
    Remove File    /tmp/connector.output
    Remove File    /tmp/connector.command.log
    Ctn Send To Connector    ${tc}    ${command}    ${timeout}
    # 1. Extract the result from the log and write to /tmp/connector.output
    Ctn Extract Result From Log    ${tc}
    # 2. Read the file
    ${output}    Get File    /tmp/connector.output
    ${output}    Strip String    ${output}
    # 3. Compare with expected
    Should Match Regexp
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected regular expression:\n${expected_result}\n
    ...    values=False


Ctn Run Command With Connector And Check Multiline Result
    [Arguments]    ${command}    ${expected_result}    ${tc}=0    ${timeout}=${TIMEOUT}
    Remove File    /tmp/connector.output
    Remove File    /tmp/connector.command.log
    Ctn Send To Connector    ${tc}    ${command}    ${timeout}
    Ctn Extract Multiline Result From Log    ${tc}    timeout=${timeout}
    ${output}    Get File    /tmp/connector.output
    ${output}    Replace String    ${output}    \n    ${SPACE}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${expected_result}
    ...    ${output}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True


Ctn Run Command And Check Result As Strings
    [Arguments]    ${command}    ${expected_result}    ${tc}=0    ${timeout}=${TIMEOUT}
    Remove File    /tmp/connector.output
    Remove File    /tmp/connector.command.log
    IF    '${tc}' == '0'
        ${tc}=    Evaluate    random.randint(0, 999999999)    random,sys
    END
    IF    "centreon_plugins.pl" in $command
        Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}
    ELSE
        Ctn Run Command With Connector And Check Result As Strings    ${command}    ${expected_result}    ${tc}    ${timeout}
    END

Ctn Run Command And Check Result As Regexp
    [Arguments]    ${command}    ${expected_result}    ${tc}=0    ${timeout}=${TIMEOUT}
    Remove File    /tmp/connector.output
    Remove File    /tmp/connector.command.log
    IF    '${tc}' == '0'
        ${tc}=    Evaluate    random.randint(0, 999999999)    random,sys
    END
    IF    "centreon_plugins.pl" in $command
        Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_result}
    ELSE
        Ctn Run Command With Connector And Check Result As Regexp    ${command}    ${expected_result}    ${tc}    ${timeout}
    END

Ctn Run Command And Check Result As Json
    [Arguments]    ${command}    ${expected}
    Log To Console    ${command}
    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    ${json_output}=    evaluate    json.loads('''${output}''')    json
    ${json_expected}=    evaluate    json.loads('''${expected}''')    json
    Dictionaries Should Be Equal    ${json_output}    ${json_expected}    ignore_keys=['end_time', 'start_time', 'duration']
    Log Dictionary    ${json_output}

Ctn Run Command And Return Parsed XML
    [Arguments]    ${command}
    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    ${parsed}=    Parse XML     ${output}
    RETURN    ${parsed}
