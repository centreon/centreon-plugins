*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::ibm::flashsystem::restapi::plugin
...                 --mode=capacity
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --port=${APIPORT}
...                 --api-path='/rest/v1'
...                 --api-username='user'
...                 --api-password='pass'
...                 --statefile-dir=/tmp


*** Test Cases ***
capacity ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc      extra_options                                                         expected_result    --
            ...       1       ${EMPTY}                                                              OK: Physical capacity: used 47.10 %, 146.48 TB, free 164.51 TB, overallocation 137 % - Logical: used 292.98 TB, free 629.20 TB - Data reduction: 1.81:1, saved 118.97 TB - Pool 'pool-a' status: online, overallocation: 137%, data reduction: no, used 32.78 %, free 629.06 TB | 'system.physical.space.usage.percentage'=47.10%;;;0;100 'system.physical.space.usage.bytes'=161056463236628B;;;0;341937121122058 'system.physical.space.free.bytes'=180880657885429B;;;0;341937121122058 'system.space.overallocation.percentage'=137%;;;0; 'system.logical.space.usage.bytes'=322134916705812B;;;0; 'system.logical.space.free.bytes'=691812716196659B;;;0; 'system.data.reduction.ratio.count'=1.81;;;0; 'system.data.reduction.saved.bytes'=130808898356510B;;;0; 'pool-a#pool.space.usage.percentage'=32.78%;;;0;100 'pool-a#pool.space.free.bytes'=691658784568770B;;;0;
            ...       2       --warning-physical-usage-prct=40 --critical-physical-usage-prct=90    WARNING: Physical capacity: used 47.10 % | 'system.physical.space.usage.percentage'=47.10%;0:40;0:90;0;100 'system.physical.space.usage.bytes'=161056463236628B;;;0;341937121122058 'system.physical.space.free.bytes'=180880657885429B;;;0;341937121122058 'system.space.overallocation.percentage'=137%;;;0; 'system.logical.space.usage.bytes'=322134916705812B;;;0; 'system.logical.space.free.bytes'=691812716196659B;;;0; 'system.data.reduction.ratio.count'=1.81;;;0; 'system.data.reduction.saved.bytes'=130808898356510B;;;0; 'pool-a#pool.space.usage.percentage'=32.78%;;;0;100 'pool-a#pool.space.free.bytes'=691658784568770B;;;0;
            ...       3       --filter-pool='nomatch'                                               OK: Physical capacity: used 47.10 %, 146.48 TB, free 164.51 TB, overallocation 137 % - Logical: used 292.98 TB, free 629.20 TB - Data reduction: 1.81:1, saved 118.97 TB | 'system.physical.space.usage.percentage'=47.10%;;;0;100 'system.physical.space.usage.bytes'=161056463236628B;;;0;341937121122058 'system.physical.space.free.bytes'=180880657885429B;;;0;341937121122058 'system.space.overallocation.percentage'=137%;;;0; 'system.logical.space.usage.bytes'=322134916705812B;;;0; 'system.logical.space.free.bytes'=691812716196659B;;;0; 'system.data.reduction.ratio.count'=1.81;;;0; 'system.data.reduction.saved.bytes'=130808898356510B;;;0;
            ...       4       --critical-pool-status='\\\%{status} =~ /online/'                        CRITICAL: Pool 'pool-a' status: online, overallocation: 137%, data reduction: no | 'system.physical.space.usage.percentage'=47.10%;;;0;100 'system.physical.space.usage.bytes'=161056463236628B;;;0;341937121122058 'system.physical.space.free.bytes'=180880657885429B;;;0;341937121122058 'system.space.overallocation.percentage'=137%;;;0; 'system.logical.space.usage.bytes'=322134916705812B;;;0; 'system.logical.space.free.bytes'=691812716196659B;;;0; 'system.data.reduction.ratio.count'=1.81;;;0; 'system.data.reduction.saved.bytes'=130808898356510B;;;0; 'pool-a#pool.space.usage.percentage'=32.78%;;;0;100 'pool-a#pool.space.free.bytes'=691658784568770B;;;0;
            ...       5       --filter-counters='data-reduction'                                    OK: Data reduction: 1.81:1, saved 118.97 TB - Pool 'pool-a' | 'system.data.reduction.ratio.count'=1.81;;;0; 'system.data.reduction.saved.bytes'=130808898356510B;;;0;
