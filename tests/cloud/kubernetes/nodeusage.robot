*** Settings ***
Documentation       Cloud Kubernetes kubectl node-usage

Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=cloud::kubernetes::plugin
...         --mode=node-usage
...         --custommode=kubectl
...         --command=${CURDIR}${/}kubectl_bin${/}kubectl


*** Test Cases ***
Node Usage ${tc}
    [Tags]    cloud    kubernetes
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extraoptions
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Node 'kind-control-plane' CPU requests: 1.25% (0.1/8), Memory requests: 0.22% (70.00MB/31.07GB), Memory limits: 0.53% (170.00MB/31.07GB), Pods allocation: 0.91% (1/110) | 'kind-control-plane#cpu.requests.percentage'=1.25%;;;0;100 'kind-control-plane#memory.requests.percentage'=0.22%;;;0;100 'kind-control-plane#memory.limits.percentage'=0.53%;;;0;100 'kind-control-plane#pods.allocation.percentage'=0.91%;;;0;100
    ...    2
    ...    --include-status='unknown'
    ...    UNKNOWN: No Pods found.
    ...    3
    ...    --exclude-status='running'
    ...    UNKNOWN: No Pods found.
    ...    4
    ...    --include-name='none'
    ...    UNKNOWN: No Nodes found.
    ...    5
    ...    --exclude-name='kind-control-plane'
    ...    UNKNOWN: No Nodes found.
