*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vcenter::plugin
...                 --mode=cluster-status
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000

*** Test Cases ***
Cluster-Status ${tc}
    [Tags]    apps    api    vmware   vsphere8    vcenter
    ${command}    Catenate    ${CMD} ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}
    
    
    Examples:    tc     extraoptions                                             expected_result   --
        ...      1      ${EMPTY}                                                 WARNING: 'EXT-CLU01' has DRS disabled
        ...      2      --warning-drs-status='\\\%{drs_enabled} ne "true"'       WARNING: 'EXT-CLU01' has DRS disabled
        ...      3      --critical-drs-status='\\\%{drs_enabled} ne "true"'      CRITICAL: 'EXT-CLU01' has DRS disabled
        ...      4      --warning-drs-status=0                                   OK: 'EXT-CLU01' has HA enabled, 'EXT-CLU01' has DRS disabled
        ...      5      --warning-ha-status='\\\%{ha_enabled} ne "true"'         WARNING: 'EXT-CLU01' has DRS disabled
        ...      6      --warning-ha-status='\\\%{ha_enabled} eq "true"'         WARNING: 'EXT-CLU01' has HA enabled, 'EXT-CLU01' has DRS disabled
        ...      7      --critical-ha-status='\\\%{ha_enabled} ne "true"'        WARNING: 'EXT-CLU01' has DRS disabled
        ...      8      --critical-ha-status='\\\%{ha_enabled} eq "true"'        CRITICAL: 'EXT-CLU01' has HA enabled, 'EXT-CLU01' has DRS disabled
        ...      9      --include-name='EXT-CLU01'                               WARNING: 'EXT-CLU01' has DRS disabled
        ...      10     --exclude-name='EXT-CLU01'                               UNKNOWN: No clusters found.
        ...      11     --include-name='no match'                                UNKNOWN: No clusters found.
