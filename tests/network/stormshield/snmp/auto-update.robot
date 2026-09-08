*** Settings ***
Documentation       network::stormshield::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::stormshield::snmp::plugin
...         --mode=auto-update
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-version=${SNMPVERSION}
...         --snmp-community=network/stormshield/snmp/sn910


*** Test Cases ***
Auto-update ${tc}
    [Tags]    network    stormshield    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    CRITICAL: Update: Patterns is broken - Update: CustomPatterns has failed
    ...    2
    ...    --unknown-status='${PERCENT}\\{state\\} eq "Failed"' --warning-status= --critical-status=
    ...    UNKNOWN: Update: CustomPatterns has failed
    ...    3
    ...    --warning-status='${PERCENT}\\{state\\} eq "Failed"' --critical-status= --unknown-status=
    ...    WARNING: Update: CustomPatterns has failed
    ...    4
    ...    --critical-status='${PERCENT}\\{state\\} eq "Failed"' --unknown-status= --warning-status=
    ...    CRITICAL: Update: CustomPatterns has failed
    ...    5
    ...    --critical-status= --unknown-status= --warning-status= --verbose
    ...    OK: All Updates and Webservices are up to date Update: Antispam never started Update: Metadata never started Update: CustomWebServices is disabled Update: Patterns is broken Update: CustomPatterns has failed Update: AdvancedAV never started Update: URLFiltering never started Update: CompromisedUrls never started Update: Vaderetro never started Update: RootCertificates never started Update: IPData never started
