*** Settings ***
Documentation     Cloud Kubernetes kubectl resourcequotas

Resource          ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup       Ctn Generic Suite Setup
Suite Teardown    Ctn Generic Suite Teardown
Test Timeout      120s


*** Variables ***
${CMD}    ${CENTREON_PLUGINS}
...       --plugin=cloud::kubernetes::plugin
...       --mode=resourcequota-status
...       --custommode=kubectl
...       --command=${CURDIR}${/}kubectl_bin${/}kubectl


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
    ...    8
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>uid</element> <element>name</element> <element>namespace</element> </data>
    ...    9
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label name="host-network-namespace-quotas" namespace="openshift-host-network" uid="0c8d5578-3e35-4d15-a39e-783ffe1588bb"/> <label name="quota-test" namespace="test-quota" uid="4edc7c98-4aa9-4e37-92ee-c48085c5e6ae"/> </data>
    ...    10
    ...    --namespace=test-units
    ...    OK: All ResourceQuota resources are ok | 'quota-cpu-mixed~limits.cpu#resource.usage.percent'=25%;;;0;100 'quota-cpu-mixed~limits.cpu#resource.used'=0.5;;;; 'quota-cpu-mixed~limits.cpu#resource.hard'=2;;;; 'quota-cpu-mixed~requests.cpu#resource.usage.percent'=20%;;;0;100 'quota-cpu-mixed~requests.cpu#resource.used'=0.2;;;; 'quota-cpu-mixed~requests.cpu#resource.hard'=1;;;; 'quota-cpu-millicores~requests.cpu#resource.usage.percent'=26.6666666666667%;;;0;100 'quota-cpu-millicores~requests.cpu#resource.used'=0.8;;;; 'quota-cpu-millicores~requests.cpu#resource.hard'=3;;;; 'quota-hugepages~requests.hugepages-2Mi#resource.usage.percent'=50%;;;0;100 'quota-hugepages~requests.hugepages-2Mi#resource.used'=536870912;;;; 'quota-hugepages~requests.hugepages-2Mi#resource.hard'=1073741824;;;;
    ...    11
    ...    --namespace=test-units --exclude-resource='hugepages' --warning-usage='\\\%{usage_percent} > 21'
    ...    WARNING: Quota 'test-units/quota-cpu-mixed' Resource 'limits.cpu' Usage: 500m/2 (25.00%) - Quota 'test-units/quota-cpu-millicores' Resource 'requests.cpu' Usage: 800m/3000m (26.67%) | 'quota-cpu-mixed~limits.cpu#resource.usage.percent'=25%;;;0;100 'quota-cpu-mixed~limits.cpu#resource.used'=0.5;;;; 'quota-cpu-mixed~limits.cpu#resource.hard'=2;;;; 'quota-cpu-mixed~requests.cpu#resource.usage.percent'=20%;;;0;100 'quota-cpu-mixed~requests.cpu#resource.used'=0.2;;;; 'quota-cpu-mixed~requests.cpu#resource.hard'=1;;;; 'quota-cpu-millicores~requests.cpu#resource.usage.percent'=26.6666666666667%;;;0;100 'quota-cpu-millicores~requests.cpu#resource.used'=0.8;;;; 'quota-cpu-millicores~requests.cpu#resource.hard'=3;;;;
    ...    12
    ...    --namespace=test-units --include-resource='hugepages' --critical-usage='\\\%{usage_percent} > 40'
    ...    CRITICAL: Quota 'test-units/quota-hugepages' Resource 'requests.hugepages-2Mi' Usage: 512Mi/1Gi (50.00%) | 'quota-hugepages~requests.hugepages-2Mi#resource.usage.percent'=50%;;;0;100 'quota-hugepages~requests.hugepages-2Mi#resource.used'=536870912;;;; 'quota-hugepages~requests.hugepages-2Mi#resource.hard'=1073741824;;;;
