*** Settings ***
Documentation       Check current HA-State. HA-States: notapplicable, auxiliary, standAlone,primary, faulty, ready.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cyberoam::snmp::plugin


*** Test Cases ***
ha-status ${tc}
    [Tags]    network    cyberoam
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=license
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cyberoam/snmp/slim_sophos
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command Without Connector And Check Result As Regexp    ${tc}    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                          expected_result    --
            ...      1     ${EMPTY}                                                               OK: All licenses are ok \\\\| 'base_fw#license.expires.seconds'=\\\\d+s;;;0; 'net_protection#license.expires.seconds'=\\\\d+s;;;0; 'web_protection#license.expires.seconds'=\\\\d+s;;;0;
            ...      2     --unit=w                                                               OK: All licenses are ok \\\\| 'base_fw#license.expires.weeks'=\\\\d+w;;;0; 'net_protection#license.expires.weeks'=\\\\d+w;;;0; 'web_protection#license.expires.weeks'=\\\\d+w;;;0;
            ...      3     --unit=w --warning-expires=0                                           WARNING: License 'base_fw' expires in.* \\\\| 'base_fw#license.expires.weeks'=\\\\d+w;0:0;;0; 'net_protection#license.expires.weeks'=\\\\d+w;0:0;;0; 'web_protection#license.expires.weeks'=\\\\d+w;0:0;;0;
            ...      4     --unit=w --critical-expires=0                                          CRITICAL: License 'base_fw' expires in.* \\\\| 'base_fw#license.expires.weeks'=\\\\d+w;;0:0;0; 'net_protection#license.expires.weeks'=\\\\d+w;;0:0;0; 'web_protection#license.expires.weeks'=\\\\d+w;;0:0;0;
            ...      5     --unit=w --warning-expires=1000000:                                    WARNING: License 'base_fw' expires in.* \\\\| 'base_fw#license.expires.weeks'=\\\\d+w;1000000:;;0; 'net_protection#license.expires.weeks'=\\\\d+w;1000000:;;0; 'web_protection#license.expires.weeks'=\\\\d+w;1000000:;;0;
            ...      6     --unit=w --critical-expires=1000000:                                   CRITICAL: License 'base_fw' expires in.* \\\\| 'base_fw#license.expires.weeks'=\\\\d+w;;1000000:;0; 'net_protection#license.expires.weeks'=\\\\d+w;;1000000:;0; 'web_protection#license.expires.weeks'=\\\\d+w;;1000000:;0;
