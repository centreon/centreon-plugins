*** Settings ***
Documentation       Check EMC DataDomain in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::emc::datadomain::snmp::plugin


*** Test Cases ***
list-mtrees ${tc}
    [Tags]    snmp  storage
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-mtrees
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/emc/datadomain/snmp/slim-datadomain
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                 expected_result    --
            ...      1     --verbose                                                     List MTrees: [name = /data/col1/SQL_prod_DTX][status = readOnly] [name = /data/col1/Veeam_StorageUnit_DTX][status = readOnly] [name = /data/col1/Veeam_StorageUnit_PA6][status = retentionLockEnabled] [name = /data/col1/backup][status = readWrite] [name = /data/col1/cofpr3ubkp01p][status = readWrite]
