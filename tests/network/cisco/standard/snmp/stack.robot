*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
stack ${tc}
    [Tags]    network    stack    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=stack
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/cisco
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                               expected_result    --
            ...      1     ${EMPTY}                                                                                    OK: Stack status is 'redundant' - Number of members waiting: 0, progressing: 0, added: 0, ready: 3, SDM mismatch: 0, version mismatch: 0, feature mismatch: 0, new master init: 0, provisioned: 0, invalid: 0, removed: 0 - All stack members status are ok | 'waiting'=0;;;0; 'progressing'=0;;;0; 'added'=0;;;0; 'ready'=3;;;0; 'sdm_mismatch'=0;;;0; 'version_mismatch'=0;;;0; 'feature_mismatch'=0;;;0; 'new_master_init'=0;;;0; 'provisioned'=0;;;0; 'invalid'=0;;;0; 'removed'=0;;;0;
            ...      2     --critical-status='\\\%{role} =~ /master/'                                                  CRITICAL: Member 'Anonymized 250' state is 'ready', role is 'master' | 'waiting'=0;;;0; 'progressing'=0;;;0; 'added'=0;;;0; 'ready'=3;;;0; 'sdm_mismatch'=0;;;0; 'version_mismatch'=0;;;0; 'feature_mismatch'=0;;;0; 'new_master_init'=0;;;0; 'provisioned'=0;;;0; 'invalid'=0;;;0; 'removed'=0;;;0;
            ...      3     --warning-stack-status='\\\%{stack_status} =~ /redundant/'                                  WARNING: Stack status is 'redundant' | 'waiting'=0;;;0; 'progressing'=0;;;0; 'added'=0;;;0; 'ready'=3;;;0; 'sdm_mismatch'=0;;;0; 'version_mismatch'=0;;;0; 'feature_mismatch'=0;;;0; 'new_master_init'=0;;;0; 'provisioned'=0;;;0; 'invalid'=0;;;0; 'removed'=0;;;0;
            ...      4     --critical-stack-status='\\\%{stack_status} =~ /redundant/'                                 CRITICAL: Stack status is 'redundant' | 'waiting'=0;;;0; 'progressing'=0;;;0; 'added'=0;;;0; 'ready'=3;;;0; 'sdm_mismatch'=0;;;0; 'version_mismatch'=0;;;0; 'feature_mismatch'=0;;;0; 'new_master_init'=0;;;0; 'provisioned'=0;;;0; 'invalid'=0;;;0; 'removed'=0;;;0;
            ...      5     --warning-status='\\\%{state} =~ /ready/'                                                   WARNING: Member 'Anonymized 250' state is 'ready', role is 'master' - Member 'Anonymized 127' state is 'ready', role is 'member' - Member 'Anonymized 094' state is 'ready', role is 'member' | 'waiting'=0;;;0; 'progressing'=0;;;0; 'added'=0;;;0; 'ready'=3;;;0; 'sdm_mismatch'=0;;;0; 'version_mismatch'=0;;;0; 'feature_mismatch'=0;;;0; 'new_master_init'=0;;;0; 'provisioned'=0;;;0; 'invalid'=0;;;0; 'removed'=0;;;0;
            ...      6     --warning-waiting=@0:10 --critical-waiting=@2:2                                             WARNING: Number of members waiting: 0 | 'waiting'=0;@0:10;@2:2;0; 'progressing'=0;;;0; 'added'=0;;;0; 'ready'=3;;;0; 'sdm_mismatch'=0;;;0; 'version_mismatch'=0;;;0; 'feature_mismatch'=0;;;0; 'new_master_init'=0;;;0; 'provisioned'=0;;;0; 'invalid'=0;;;0; 'removed'=0;;;0;
