*** Settings ***
Library           Process
Library           OperatingSystem
Library           CentreonConnectorLibrary    /tmp/centreon_connector.pipe

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Centreon Connector
Suite Teardown    Stop Centreon Connector

*** Variables ***
${CONNECTOR_PATH}        /usr/lib64/centreon-connector/centreon_connector_perl
${PLUGIN_COMMAND}        /usr/lib/centreon/plugins/centreon_linux_snmp.pl --plugin os::linux::snmp::plugin --mode cpu --hostname 127.0.0.1 --snmp-community=os/linux/snmp/network-interfaces --snmp-port 2024 --snmp-version 2c --snmp-timeout 1
${CONNECTOR_CMD}         /usr/lib64/centreon-connector/centreon_connector_perl --log-file=/dev/null
${CONNECTOR_PID_FILE}    /tmp/centreon_connector.pid
${EXPECTED_OUTPUT}      OK: CPU usage

*** Keywords ***
Start Centreon Connector
    Log    Starting Centreon Connector...
    Run Process    sh    -c    cat test_file.bin | ${CONNECTOR_CMD} & echo $! > ${CONNECTOR_PID_FILE}
    Sleep    1s
    Log    Centreon Connector started

Stop Centreon Connector
    Log    Stopping Centreon Connector...
    ${exists}=    Run Keyword And Return Status    File Should Exist    ${CONNECTOR_PID_FILE}
    Run Keyword If    not ${exists}    Fail    No PID file found. Can't stop connector.
    ${pid}=    Get File    ${CONNECTOR_PID_FILE}
    Run Process    kill    ${pid}
    Remove File    ${CONNECTOR_PID_FILE}
    Log    Centreon Connector stopped

Send Centreon Command
    [Arguments]    ${command}
    Log    Sending command to Centreon Connector: ${command}
    Run Process    echo "${command}" > /tmp/centreon_connector.pipe    shell=True

*** Test Cases ***
Check CPU Plugin
    Send Centreon Command    /usr/lib/centreon/plugins/centreon_linux_local.pl --plugin os::linux::local::plugin --mode cpu
    ${output}=    Get Centreon Response
    Should Contain    ${output}    ${EXPECTED_OUTPUT}   #a changer pour dhould equal as string


#on doit avoir un identifiant unique pour chaque test case, sinon on va avoir des conflits entre les test
#Get Centreon Response il doit envoier juste le resultat de la commande, sans id 