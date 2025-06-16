*** Settings ***
Library    Process
Library    Collections
Library           CentreonConnectorLibrary.py


Suite Setup       Start Centreon Connector
Suite Teardown    Stop Centreon Connector

*** Variables ***
${PERL_CONNECTOR}    /usr/lib64/centreon-connector/centreon_connector_perl
${PLUGIN_COMMAND}    /usr/lib/centreon/plugins/centreon_linux_snmp.pl --plugin os::linux::snmp::plugin --mode cpu --hostname 127.0.0.1 --snmp-community=os/linux/snmp/network-interfaces --snmp-port 2024 --snmp-version 2c --snmp-timeout 1

${EXAMPLES}    --plugin=os::linux::snmp::plugin --mode=arp

*** Test Cases ***
Run Each Example
    FOR    ${example}    IN    ${EXAMPLES}
         Execute Perl Command    ${example}
    END
    Log    All examples executed successfully

*** Keywords ***
Execute Perl Command
    [Arguments]    ${example}
    ${result}=    Run Process    ${PERL_CONNECTOR}    ${example}    shell=True    stdout=YES    stderr=YES
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0