*** Settings ***
Documentation       Network citrix netscaler health

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
stack ${tc}
    [Tags]    network    citrix    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=stack
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/cisco
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                     expected_result    --
            ...      1     --critical-status='\\\%{state} !~ /ready/ && \\\%{state} !~ /provisioned/'        OK: Stack status is 'redundant' - Number of members waiting: 0, progressing: 0, added: 0, ready: 3, SDM mismatch: 0, version mismatch: 0, feature mismatch: 0, new master init: 0, provisioned: 0, invalid: 0, removed: 0 - All stack members status are ok | 'waiting'=0;;;0; 'progressing'=0;;;0; 'added'=0;;;0; 'ready'=3;;;0; 'sdm_mismatch'=0;;;0; 'version_mismatch'=0;;;0; 'feature_mismatch'=0;;;0; 'new_master_init'=0;;;0; 'provisioned'=0;;;0; 'invalid'=0;;;0; 'removed'=0;;;0;
            ...      2     --warning-status                                                                  OK: Stack status is 'redundant' - Number of members waiting: 0, progressing: 0, added: 0, ready: 3, SDM mismatch: 0, version mismatch: 0, feature mismatch: 0, new master init: 0, provisioned: 0, invalid: 0, removed: 0 - All stack members status are ok | 'waiting'=0;;;0; 'progressing'=0;;;0; 'added'=0;;;0; 'ready'=3;;;0; 'sdm_mismatch'=0;;;0; 'version_mismatch'=0;;;0; 'feature_mismatch'=0;;;0; 'new_master_init'=0;;;0; 'provisioned'=0;;;0; 'invalid'=0;;;0; 'removed'=0;;;0; 
            ...      3     --critical-status                                                                 OK: Stack status is 'redundant' - Number of members waiting: 0, progressing: 0, added: 0, ready: 3, SDM mismatch: 0, version mismatch: 0, feature mismatch: 0, new master init: 0, provisioned: 0, invalid: 0, removed: 0 - All stack members status are ok | 'waiting'=0;;;0; 'progressing'=0;;;0; 'added'=0;;;0; 'ready'=3;;;0; 'sdm_mismatch'=0;;;0; 'version_mismatch'=0;;;0; 'feature_mismatch'=0;;;0; 'new_master_init'=0;;;0; 'provisioned'=0;;;0; 'invalid'=0;;;0; 'removed'=0;;;0;     
            ...      4     --verbose                                                                         OK: Stack status is 'redundant' - Number of members waiting: 0, progressing: 0, added: 0, ready: 3, SDM mismatch: 0, version mismatch: 0, feature mismatch: 0, new master init: 0, provisioned: 0, invalid: 0, removed: 0 - All stack members status are ok | 'waiting'=0;;;0; 'progressing'=0;;;0; 'added'=0;;;0; 'ready'=3;;;0; 'sdm_mismatch'=0;;;0; 'version_mismatch'=0;;;0; 'feature_mismatch'=0;;;0; 'new_master_init'=0;;;0; 'provisioned'=0;;;0; 'invalid'=0;;;0; 'removed'=0;;;0; Member 'Anonymized 250' state is 'ready', role is 'master' Member 'Anonymized 127' state is 'ready', role is 'member' Member 'Anonymized 094' state is 'ready', role is 'member'
