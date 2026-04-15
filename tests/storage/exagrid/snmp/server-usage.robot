*** Settings ***
Documentation       Check Exagrid server usage

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::exagrid::snmp::plugin


*** Test Cases ***
Server Usage ${tc}
    [Tags]    snmp    storage    exagrid
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=server-usage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/exagrid/snmp/exagrid
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Server Status : ok - Landing Usage Total: 31.88 TB Used: 0.00 B (0.00%) Free: 31.88 TB (100.00%) - Retention Usage Total: 0.00 B Used: 0.00 B (0.00%) Free: 0.00 B (0.00%) | 'landing_used'=0B;;;0;35054000000000 'retention_used'=0B;;;0;0
    ...    2
    ...    --warning-landing-usage=1:
    ...    WARNING: Landing Usage Total: 31.88 TB Used: 0.00 B (0.00%) Free: 31.88 TB (100.00%) | 'landing_used'=0B;350540000000:;;0;35054000000000 'retention_used'=0B;;;0;0
    ...    3
    ...    --critical-landing-usage=1:
    ...    CRITICAL: Landing Usage Total: 31.88 TB Used: 0.00 B (0.00%) Free: 31.88 TB (100.00%) | 'landing_used'=0B;;350540000000:;0;35054000000000 'retention_used'=0B;;;0;0
    ...    4
    ...    --warning-landing-usage=1:
    ...    WARNING: Landing Usage Total: 31.88 TB Used: 0.00 B (0.00%) Free: 31.88 TB (100.00%) | 'landing_used'=0B;350540000000:;;0;35054000000000 'retention_used'=0B;;;0;0
    ...    5
    ...    --critical-landing-usage=1:
    ...    CRITICAL: Landing Usage Total: 31.88 TB Used: 0.00 B (0.00%) Free: 31.88 TB (100.00%) | 'landing_used'=0B;;350540000000:;0;35054000000000 'retention_used'=0B;;;0;0
    ...    6
    ...    --warning-status='\\\%{status} !~ /error/'
    ...    WARNING: Server Status : ok | 'landing_used'=0B;;;0;35054000000000 'retention_used'=0B;;;0;0
    ...    7
    ...    --critical-status='\\\%{status} !~ /error/'
    ...    CRITICAL: Server Status : ok | 'landing_used'=0B;;;0;35054000000000 'retention_used'=0B;;;0;0
