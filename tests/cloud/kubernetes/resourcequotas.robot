*** Settings ***
Documentation       Cloud Kubernetes kubectl resourcequotas

Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=cloud::kubernetes::plugin
...         --mode=resourcequota-status
...         --custommode=kubectl
...         --command=${CURDIR}${/}kubectl_bin${/}kubectl


*** Test Cases ***
ResourceQuota ${tc}
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
    ...    OK: All ResourceQuota resources are ok | 'host-network-namespace-quotas~count/daemonsets.apps#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~count/daemonsets.apps#resource.used'=0;;;; 'host-network-namespace-quotas~count/daemonsets.apps#resource.hard'=0;;;; 'host-network-namespace-quotas~count/deployments.apps#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~count/deployments.apps#resource.used'=0;;;; 'host-network-namespace-quotas~count/deployments.apps#resource.hard'=0;;;; 'host-network-namespace-quotas~limits.cpu#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~limits.cpu#resource.used'=0;;;; 'host-network-namespace-quotas~limits.cpu#resource.hard'=0;;;; 'host-network-namespace-quotas~limits.memory#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~limits.memory#resource.used'=0;;;; 'host-network-namespace-quotas~limits.memory#resource.hard'=0;;;; 'host-network-namespace-quotas~pods#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~pods#resource.used'=0;;;; 'host-network-namespace-quotas~pods#resource.hard'=0;;;; 'quota-test~limits.cpu#resource.usage.percent'=0%;;;0;100 'quota-test~limits.cpu#resource.used'=0;;;; 'quota-test~limits.cpu#resource.hard'=4;;;; 'quota-test~limits.memory#resource.usage.percent'=0%;;;0;100 'quota-test~limits.memory#resource.used'=0;;;; 'quota-test~limits.memory#resource.hard'=4294967296;;;; 'quota-test~pods#resource.usage.percent'=0%;;;0;100 'quota-test~pods#resource.used'=0;;;; 'quota-test~pods#resource.hard'=10;;;; 'quota-test~requests.cpu#resource.usage.percent'=0%;;;0;100 'quota-test~requests.cpu#resource.used'=0;;;; 'quota-test~requests.cpu#resource.hard'=2;;;; 'quota-test~requests.memory#resource.usage.percent'=50%;;;0;100 'quota-test~requests.memory#resource.used'=1073741824;;;; 'quota-test~requests.memory#resource.hard'=2147483648;;;;
    ...    2
    ...    --exclude-name='quota-test'
    ...    OK: All ResourceQuota resources are ok | 'host-network-namespace-quotas~count/daemonsets.apps#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~count/daemonsets.apps#resource.used'=0;;;; 'host-network-namespace-quotas~count/daemonsets.apps#resource.hard'=0;;;; 'host-network-namespace-quotas~count/deployments.apps#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~count/deployments.apps#resource.used'=0;;;; 'host-network-namespace-quotas~count/deployments.apps#resource.hard'=0;;;; 'host-network-namespace-quotas~limits.cpu#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~limits.cpu#resource.used'=0;;;; 'host-network-namespace-quotas~limits.cpu#resource.hard'=0;;;; 'host-network-namespace-quotas~limits.memory#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~limits.memory#resource.used'=0;;;; 'host-network-namespace-quotas~limits.memory#resource.hard'=0;;;; 'host-network-namespace-quotas~pods#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~pods#resource.used'=0;;;; 'host-network-namespace-quotas~pods#resource.hard'=0;;;;
    ...    3
    ...    --exclude-namespace='test-quota'
    ...    OK: All ResourceQuota resources are ok | 'host-network-namespace-quotas~count/daemonsets.apps#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~count/daemonsets.apps#resource.used'=0;;;; 'host-network-namespace-quotas~count/daemonsets.apps#resource.hard'=0;;;; 'host-network-namespace-quotas~count/deployments.apps#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~count/deployments.apps#resource.used'=0;;;; 'host-network-namespace-quotas~count/deployments.apps#resource.hard'=0;;;; 'host-network-namespace-quotas~limits.cpu#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~limits.cpu#resource.used'=0;;;; 'host-network-namespace-quotas~limits.cpu#resource.hard'=0;;;; 'host-network-namespace-quotas~limits.memory#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~limits.memory#resource.used'=0;;;; 'host-network-namespace-quotas~limits.memory#resource.hard'=0;;;; 'host-network-namespace-quotas~pods#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~pods#resource.used'=0;;;; 'host-network-namespace-quotas~pods#resource.hard'=0;;;;
    ...    4
    ...    --warning-usage='\\\%{usage_percent} > 10' --include-name="quota-test"
    ...    WARNING: Quota 'test-quota/quota-test' Resource 'requests.memory' Usage: 1Gi/2Gi (50.00%) | 'quota-test~limits.cpu#resource.usage.percent'=0%;;;0;100 'quota-test~limits.cpu#resource.used'=0;;;; 'quota-test~limits.cpu#resource.hard'=4;;;; 'quota-test~limits.memory#resource.usage.percent'=0%;;;0;100 'quota-test~limits.memory#resource.used'=0;;;; 'quota-test~limits.memory#resource.hard'=4294967296;;;; 'quota-test~pods#resource.usage.percent'=0%;;;0;100 'quota-test~pods#resource.used'=0;;;; 'quota-test~pods#resource.hard'=10;;;; 'quota-test~requests.cpu#resource.usage.percent'=0%;;;0;100 'quota-test~requests.cpu#resource.used'=0;;;; 'quota-test~requests.cpu#resource.hard'=2;;;; 'quota-test~requests.memory#resource.usage.percent'=50%;;;0;100 'quota-test~requests.memory#resource.used'=1073741824;;;; 'quota-test~requests.memory#resource.hard'=2147483648;;;;
    ...    5
    ...    --critical-usage='\\\%{usage_percent} > 10' --include-name="quota-test"
    ...    CRITICAL: Quota 'test-quota/quota-test' Resource 'requests.memory' Usage: 1Gi/2Gi (50.00%) | 'quota-test~limits.cpu#resource.usage.percent'=0%;;;0;100 'quota-test~limits.cpu#resource.used'=0;;;; 'quota-test~limits.cpu#resource.hard'=4;;;; 'quota-test~limits.memory#resource.usage.percent'=0%;;;0;100 'quota-test~limits.memory#resource.used'=0;;;; 'quota-test~limits.memory#resource.hard'=4294967296;;;; 'quota-test~pods#resource.usage.percent'=0%;;;0;100 'quota-test~pods#resource.used'=0;;;; 'quota-test~pods#resource.hard'=10;;;; 'quota-test~requests.cpu#resource.usage.percent'=0%;;;0;100 'quota-test~requests.cpu#resource.used'=0;;;; 'quota-test~requests.cpu#resource.hard'=2;;;; 'quota-test~requests.memory#resource.usage.percent'=50%;;;0;100 'quota-test~requests.memory#resource.used'=1073741824;;;; 'quota-test~requests.memory#resource.hard'=2147483648;;;;
    ...    6
    ...    --include-resource='memory'
    ...    OK: All ResourceQuota resources are ok | 'host-network-namespace-quotas~limits.memory#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~limits.memory#resource.used'=0;;;; 'host-network-namespace-quotas~limits.memory#resource.hard'=0;;;; 'quota-test~limits.memory#resource.usage.percent'=0%;;;0;100 'quota-test~limits.memory#resource.used'=0;;;; 'quota-test~limits.memory#resource.hard'=4294967296;;;; 'quota-test~requests.memory#resource.usage.percent'=50%;;;0;100 'quota-test~requests.memory#resource.used'=1073741824;;;; 'quota-test~requests.memory#resource.hard'=2147483648;;;;
    ...    7
    ...    --exclude-resource='memory'
    ...    OK: All ResourceQuota resources are ok | 'host-network-namespace-quotas~count/daemonsets.apps#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~count/daemonsets.apps#resource.used'=0;;;; 'host-network-namespace-quotas~count/daemonsets.apps#resource.hard'=0;;;; 'host-network-namespace-quotas~count/deployments.apps#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~count/deployments.apps#resource.used'=0;;;; 'host-network-namespace-quotas~count/deployments.apps#resource.hard'=0;;;; 'host-network-namespace-quotas~limits.cpu#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~limits.cpu#resource.used'=0;;;; 'host-network-namespace-quotas~limits.cpu#resource.hard'=0;;;; 'host-network-namespace-quotas~pods#resource.usage.percent'=0%;;;0;100 'host-network-namespace-quotas~pods#resource.used'=0;;;; 'host-network-namespace-quotas~pods#resource.hard'=0;;;; 'quota-test~limits.cpu#resource.usage.percent'=0%;;;0;100 'quota-test~limits.cpu#resource.used'=0;;;; 'quota-test~limits.cpu#resource.hard'=4;;;; 'quota-test~pods#resource.usage.percent'=0%;;;0;100 'quota-test~pods#resource.used'=0;;;; 'quota-test~pods#resource.hard'=10;;;; 'quota-test~requests.cpu#resource.usage.percent'=0%;;;0;100 'quota-test~requests.cpu#resource.used'=0;;;; 'quota-test~requests.cpu#resource.hard'=2;;;;
