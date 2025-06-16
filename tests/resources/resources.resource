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

Ctn Cleanup Cache
    Remove File    ${/}var${/}lib${/}centreon${/}centplugins${/}*
    Remove File    ${/}dev${/}shm${/}*

Ctn Generic Suite Setup
   Ctn Cleanup Cache
   Set Environment Variable    TZ    UTC
   log to console    test started
   Start Connector

Ctn Run Command And Check Result As Regexp
    [Arguments]    ${command}    ${expected_result}
    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Match Regexp
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected regular expression:\n${expected_result}\n
    ...    values=False

Ctn Run Command And Check Result As Strings
    [Arguments]    ${command}    ${expected_result}
    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${expected_result}
    ...    ${output}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True

Ctn Verify Command Output
    [Arguments]    ${command}    ${expected_result}
    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Contain    
    ...    ${output}    
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True


#Clean Connector Output
#    [Arguments]    ${text}
#    ${cleaned}=    Replace String Using Regexp    ${text}    ^\d+\s+    # (empty string)
#    [Return]    ${cleaned}


#Ctn Run Command With Connector And Check Result As Strings
#    [Arguments]    ${tc}    ${command}    ${expected_result}    ${timeout}=5
#    Send To Connector    ${tc}    ${command}    ${timeout}
#    ${output}    Wait For Result    ${tc}    ${timeout}
#    ${cleaned}    Clean Connector Output    ${output}
#    Should Be Equal As Strings    ${cleaned}    ${expected_result}

#Ctn Run Command With Connector And Check Result As Strings                        #this is the code that works
#    [Arguments]    ${tc}    ${command}    ${expected_result}    ${timeout}=5
#    ${output}    Send To Connector    ${tc}    ${command}    ${timeout}
#    Log    Original output: ${output}
#    ${cleaned}    Replace String Using Regexp    ${output}    ^\\d+\\s+    ${EMPTY}
#    Log    Cleaned output: ${cleaned}
#    Should Be Equal As Strings    ${cleaned}    ${expected_result}

Ctn Run Command With Connector And Check Result As Strings
    [Arguments]    ${tc}    ${command}    ${expected_result}    ${timeout}=5
    Send To Connector    ${tc}    ${command}    ${timeout}
    # 1. Extract the result from the log and write to /tmp/connector.output
    Extract Result From Log    ${tc}
    # 2. Read the file
    ${output}    Get File    /tmp/connector.output
    ${output}    Strip String    ${output}
    # 3. Compare with expected
    Should Be Equal As Strings    ${output}    ${expected_result}

#Ctn Run Command With Connector And Check Result As Strings
#    [Arguments]    ${id}    ${command}    ${expected_result}    ${timeout}=5
#    Send To Connector    ${id}    ${command}    ${timeout}
#    ${output}=    Wait For Result    ${id}    ${timeout}
#    Log    [ID: ${id}] Output: ${output}
#    Should Contain    ${output}    ${expected_result}

    #recupere le resultat du fichier de log en decoupant le resultat en fonction de l'id je doit recevoir le resultat de la commande

Ctn Run Command With Connector And Wait For Result
    [Arguments]    ${id}    ${command}    ${timeout}
    Send To Connector    ${id}    ${command}    ${timeout}

    #surveillez le fichier de logs jusqu'a en retrouve le resultat de la commande dont l'id et $id
    # attendre la reponse dans le logs 
    #retorner l output propre sans id 'nettoiez la ligne san id sans numero'

