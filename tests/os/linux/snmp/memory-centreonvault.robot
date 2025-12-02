*** Settings ***
Documentation       Centreonvault module

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${CMD}              ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin --pass-manager=centreonvault --snmp-port=${SNMPPORT} --snmp-version=${SNMPVERSION} --hostname=${HOSTNAME}
${VAULT_CACHE}      /var/lib/centreon/centplugins/centreonvault_cache
${VAULT_FILES}      ${CURDIR}${/}..${/}..${/}..${/}centreon${/}plugins${/}passwordmgr
${MOCKOON_JSON}     ${VAULT_FILES}${/}centreonvault.mockoon.json


*** Test Cases ***
Linux Memory with vault ${tc}
    [Tags]    snmp    linux    vault    mockoon
    Remove File    ${VAULT_CACHE}
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --snmp-community=secret::hashicorp_vault::myvault/data/snmp::${secret}
    ...    --vault-config=${vault_config}
    ...    --vault-cache=${VAULT_CACHE}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:         tc  secret    vault_config                                     extra_options       expected_regexp    --
            ...       1   Linux     ${EMPTY}                                         ${EMPTY}                                   UNKNOWN: Please provide a Centreon Vault configuration file path with --vault-config option
            ...       2   Linux     ${VAULT_FILES}${/}vault.json                     ${EMPTY}                                   UNKNOWN: File '.*/centreon/plugins/passwordmgr/vault.json' could not be found.
            ...       3   Linux     ${VAULT_FILES}${/}vault_config_incomplete.json   ${EMPTY}                                   UNKNOWN: Unable to authenticate to the vault: role_id or secret_id is empty.
            ...       4   Linux     ${VAULT_FILES}${/}vault_config_plain.json        --debug                                    OK: Ram Total: 1.92 GB Used
#    ...    5    Linux    ${VAULT_FILES}${/}vault_config_encrypted.json    --vault-env-file=${VAULT_FILES}${/}env    OK: Ram Total: 1.92 GB Used
