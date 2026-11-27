*** Settings ***
Documentation     storage::ibm::flashsystem::restapi::plugin

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}flashsystem.mockoon.json

${CMD}             ${CENTREON_PLUGINS}
...                --plugin=storage::ibm::flashsystem::restapi::plugin
...                --mode=capacity
...                --hostname=${HOSTNAME}
...                --proto=http
...                --port=${APIPORT}
...                --api-username=user
...                --api-password=pass
...                --statefile-dir=/tmp


*** Test Cases ***
capacity ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
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
    ...    OK: Physical space usage total: 310.99 TB used: 146.48 TB (47.10%) free: 164.51 TB (52.90%), overallocation 137 % - Logical space usage total: 935.80 TB used: 306.60 TB (32.76%) free: 629.20 TB (67.24%) - Data reduction: 1.81:1, saved 118.97 TB - Pool 'pool-a' status: online, overallocation: 137%, data reduction: no, usage total: 935.79 TB used: 306.73 TB (32.78%) free: 629.06 TB (67.22%) | 'system.physical.space.usage.bytes'=161056463236629B;;;0;341937121122058 'system.physical.space.free.bytes'=180880657885429B;;;0;341937121122058 'system.physical.space.usage.percentage'=47.10%;;;0;100 'system.space.overallocation.percentage'=137%;;;0; 'system.logical.space.usage.bytes'=337110265076121B;;;0;1028922981272780 'system.logical.space.free.bytes'=691812716196659B;;;0;1028922981272780 'system.logical.space.usage.percentage'=32.76%;;;0;100 'system.data.reduction.ratio.count'=1.81;;;0; 'system.data.reduction.saved.bytes'=130808898356510B;;;0; 'pool-a#pool.space.usage.bytes'=337253201587733B;;;0;1028911986156503 'pool-a#pool.space.free.bytes'=691658784568770B;;;0;1028911986156503 'pool-a#pool.space.usage.percentage'=32.78%;;;0;100
    ...    2
    ...    --warning-physical-usage-prct=40 --critical-physical-usage-prct=90
    ...    WARNING: Physical space usage total: 310.99 TB used: 146.48 TB (47.10%) free: 164.51 TB (52.90%) | 'system.physical.space.usage.bytes'=161056463236629B;;;0;341937121122058 'system.physical.space.free.bytes'=180880657885429B;;;0;341937121122058 'system.physical.space.usage.percentage'=47.10%;0:40;0:90;0;100 'system.space.overallocation.percentage'=137%;;;0; 'system.logical.space.usage.bytes'=337110265076121B;;;0;1028922981272780 'system.logical.space.free.bytes'=691812716196659B;;;0;1028922981272780 'system.logical.space.usage.percentage'=32.76%;;;0;100 'system.data.reduction.ratio.count'=1.81;;;0; 'system.data.reduction.saved.bytes'=130808898356510B;;;0; 'pool-a#pool.space.usage.bytes'=337253201587733B;;;0;1028911986156503 'pool-a#pool.space.free.bytes'=691658784568770B;;;0;1028911986156503 'pool-a#pool.space.usage.percentage'=32.78%;;;0;100
    ...    3
    ...    --critical-logical-usage-prct=10
    ...    CRITICAL: Logical space usage total: 935.80 TB used: 306.60 TB (32.76%) free: 629.20 TB (67.24%) | 'system.physical.space.usage.bytes'=161056463236629B;;;0;341937121122058 'system.physical.space.free.bytes'=180880657885429B;;;0;341937121122058 'system.physical.space.usage.percentage'=47.10%;;;0;100 'system.space.overallocation.percentage'=137%;;;0; 'system.logical.space.usage.bytes'=337110265076121B;;;0;1028922981272780 'system.logical.space.free.bytes'=691812716196659B;;;0;1028922981272780 'system.logical.space.usage.percentage'=32.76%;;0:10;0;100 'system.data.reduction.ratio.count'=1.81;;;0; 'system.data.reduction.saved.bytes'=130808898356510B;;;0; 'pool-a#pool.space.usage.bytes'=337253201587733B;;;0;1028911986156503 'pool-a#pool.space.free.bytes'=691658784568770B;;;0;1028911986156503 'pool-a#pool.space.usage.percentage'=32.78%;;;0;100
    ...    4
    ...    --include-pool='nomatch'
    ...    OK: Physical space usage total: 310.99 TB used: 146.48 TB (47.10%) free: 164.51 TB (52.90%), overallocation 137 % - Logical space usage total: 935.80 TB used: 306.60 TB (32.76%) free: 629.20 TB (67.24%) - Data reduction: 1.81:1, saved 118.97 TB | 'system.physical.space.usage.bytes'=161056463236629B;;;0;341937121122058 'system.physical.space.free.bytes'=180880657885429B;;;0;341937121122058 'system.physical.space.usage.percentage'=47.10%;;;0;100 'system.space.overallocation.percentage'=137%;;;0; 'system.logical.space.usage.bytes'=337110265076121B;;;0;1028922981272780 'system.logical.space.free.bytes'=691812716196659B;;;0;1028922981272780 'system.logical.space.usage.percentage'=32.76%;;;0;100 'system.data.reduction.ratio.count'=1.81;;;0; 'system.data.reduction.saved.bytes'=130808898356510B;;;0;
    ...    5
    ...    --exclude-pool='pool-a'
    ...    OK: Physical space usage total: 310.99 TB used: 146.48 TB (47.10%) free: 164.51 TB (52.90%), overallocation 137 % - Logical space usage total: 935.80 TB used: 306.60 TB (32.76%) free: 629.20 TB (67.24%) - Data reduction: 1.81:1, saved 118.97 TB | 'system.physical.space.usage.bytes'=161056463236629B;;;0;341937121122058 'system.physical.space.free.bytes'=180880657885429B;;;0;341937121122058 'system.physical.space.usage.percentage'=47.10%;;;0;100 'system.space.overallocation.percentage'=137%;;;0; 'system.logical.space.usage.bytes'=337110265076121B;;;0;1028922981272780 'system.logical.space.free.bytes'=691812716196659B;;;0;1028922981272780 'system.logical.space.usage.percentage'=32.76%;;;0;100 'system.data.reduction.ratio.count'=1.81;;;0; 'system.data.reduction.saved.bytes'=130808898356510B;;;0;
    ...    6
    ...    --critical-pool-status='\\\%{status} =~ /online/'
    ...    CRITICAL: Pool 'pool-a' status: online, overallocation: 137%, data reduction: no | 'system.physical.space.usage.bytes'=161056463236629B;;;0;341937121122058 'system.physical.space.free.bytes'=180880657885429B;;;0;341937121122058 'system.physical.space.usage.percentage'=47.10%;;;0;100 'system.space.overallocation.percentage'=137%;;;0; 'system.logical.space.usage.bytes'=337110265076121B;;;0;1028922981272780 'system.logical.space.free.bytes'=691812716196659B;;;0;1028922981272780 'system.logical.space.usage.percentage'=32.76%;;;0;100 'system.data.reduction.ratio.count'=1.81;;;0; 'system.data.reduction.saved.bytes'=130808898356510B;;;0; 'pool-a#pool.space.usage.bytes'=337253201587733B;;;0;1028911986156503 'pool-a#pool.space.free.bytes'=691658784568770B;;;0;1028911986156503 'pool-a#pool.space.usage.percentage'=32.78%;;;0;100
    ...    7
    ...    --warning-pool-usage-free=1: --critical-pool-usage-free=:1
    ...    CRITICAL: Pool 'pool-a' usage total: 935.79 TB used: 306.73 TB (32.78%) free: 629.06 TB (67.22%) | 'system.physical.space.usage.bytes'=161056463236629B;;;0;341937121122058 'system.physical.space.free.bytes'=180880657885429B;;;0;341937121122058 'system.physical.space.usage.percentage'=47.10%;;;0;100 'system.space.overallocation.percentage'=137%;;;0; 'system.logical.space.usage.bytes'=337110265076121B;;;0;1028922981272780 'system.logical.space.free.bytes'=691812716196659B;;;0;1028922981272780 'system.logical.space.usage.percentage'=32.76%;;;0;100 'system.data.reduction.ratio.count'=1.81;;;0; 'system.data.reduction.saved.bytes'=130808898356510B;;;0; 'pool-a#pool.space.usage.bytes'=337253201587733B;;;0;1028911986156503 'pool-a#pool.space.free.bytes'=691658784568770B;1:;0:1;0;1028911986156503 'pool-a#pool.space.usage.percentage'=32.78%;;;0;100
    ...    8
    ...    --filter-counters='data-reduction' --filter-counters-block='pools'
    ...    OK: Data reduction: 1.81:1, saved 118.97 TB | 'system.data.reduction.ratio.count'=1.81;;;0; 'system.data.reduction.saved.bytes'=130808898356510B;;;0;
