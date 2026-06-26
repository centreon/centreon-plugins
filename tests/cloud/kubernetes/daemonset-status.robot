*** Settings ***
Documentation       cloud::kubernetes::plugin daemonset-status

Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=cloud::kubernetes::plugin
...         --mode=daemonset-status
...         --custommode=kubectl
...         --command=${CURDIR}${/}kubectl_bin${/}kubectl


*** Test Cases ***
Daemonset-status ${tc}
    [Tags]    cloud    kubernetes
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
    ...    OK: All DaemonSets status are ok | 'dns-default#daemonset.pods.desired.count'=1;;;; 'dns-default#daemonset.pods.current.count'=1;;;; 'dns-default#daemonset.pods.available.count'=1;;;; 'dns-default#daemonset.pods.uptodate.count'=1;;;; 'dns-default#daemonset.pods.ready.count'=1;;;; 'dns-default#daemonset.pods.misscheduled.count'=0;;;; 'dns-default#daemonset.pods.unavailable.count'=0;;;; 'node-resolver#daemonset.pods.desired.count'=1;;;; 'node-resolver#daemonset.pods.current.count'=1;;;; 'node-resolver#daemonset.pods.available.count'=1;;;; 'node-resolver#daemonset.pods.uptodate.count'=1;;;; 'node-resolver#daemonset.pods.ready.count'=1;;;; 'node-resolver#daemonset.pods.misscheduled.count'=0;;;; 'node-resolver#daemonset.pods.unavailable.count'=0;;;; 'node-ca#daemonset.pods.desired.count'=1;;;; 'node-ca#daemonset.pods.current.count'=1;;;; 'node-ca#daemonset.pods.available.count'=1;;;; 'node-ca#daemonset.pods.uptodate.count'=1;;;; 'node-ca#daemonset.pods.ready.count'=1;;;; 'node-ca#daemonset.pods.misscheduled.count'=0;;;; 'node-ca#daemonset.pods.unavailable.count'=0;;;; 'csi-hostpathplugin#daemonset.pods.desired.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.current.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.available.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.uptodate.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.ready.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.misscheduled.count'=0;;;; 'csi-hostpathplugin#daemonset.pods.unavailable.count'=0;;;;
    ...    2
    ...    --include-name=dns-default
    ...    OK: DaemonSet 'openshift-dns/dns-default' Pods Desired: 1, Current: 1, Available: 1, Unavailable: 0, Up-to-date: 1, Ready: 1, Misscheduled: 0 | 'dns-default#daemonset.pods.desired.count'=1;;;; 'dns-default#daemonset.pods.current.count'=1;;;; 'dns-default#daemonset.pods.available.count'=1;;;; 'dns-default#daemonset.pods.uptodate.count'=1;;;; 'dns-default#daemonset.pods.ready.count'=1;;;; 'dns-default#daemonset.pods.misscheduled.count'=0;;;; 'dns-default#daemonset.pods.unavailable.count'=0;;;;
    ...    3
    ...    --exclude-name=dns-default
    ...    OK: All DaemonSets status are ok | 'node-resolver#daemonset.pods.desired.count'=1;;;; 'node-resolver#daemonset.pods.current.count'=1;;;; 'node-resolver#daemonset.pods.available.count'=1;;;; 'node-resolver#daemonset.pods.uptodate.count'=1;;;; 'node-resolver#daemonset.pods.ready.count'=1;;;; 'node-resolver#daemonset.pods.misscheduled.count'=0;;;; 'node-resolver#daemonset.pods.unavailable.count'=0;;;; 'node-ca#daemonset.pods.desired.count'=1;;;; 'node-ca#daemonset.pods.current.count'=1;;;; 'node-ca#daemonset.pods.available.count'=1;;;; 'node-ca#daemonset.pods.uptodate.count'=1;;;; 'node-ca#daemonset.pods.ready.count'=1;;;; 'node-ca#daemonset.pods.misscheduled.count'=0;;;; 'node-ca#daemonset.pods.unavailable.count'=0;;;; 'csi-hostpathplugin#daemonset.pods.desired.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.current.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.available.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.uptodate.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.ready.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.misscheduled.count'=0;;;; 'csi-hostpathplugin#daemonset.pods.unavailable.count'=0;;;;
    ...    4
    ...    --include-namespace=openshift-dns
    ...    OK: All DaemonSets status are ok | 'dns-default#daemonset.pods.desired.count'=1;;;; 'dns-default#daemonset.pods.current.count'=1;;;; 'dns-default#daemonset.pods.available.count'=1;;;; 'dns-default#daemonset.pods.uptodate.count'=1;;;; 'dns-default#daemonset.pods.ready.count'=1;;;; 'dns-default#daemonset.pods.misscheduled.count'=0;;;; 'dns-default#daemonset.pods.unavailable.count'=0;;;; 'node-resolver#daemonset.pods.desired.count'=1;;;; 'node-resolver#daemonset.pods.current.count'=1;;;; 'node-resolver#daemonset.pods.available.count'=1;;;; 'node-resolver#daemonset.pods.uptodate.count'=1;;;; 'node-resolver#daemonset.pods.ready.count'=1;;;; 'node-resolver#daemonset.pods.misscheduled.count'=0;;;; 'node-resolver#daemonset.pods.unavailable.count'=0;;;;
    ...    5
    ...    --exclude-namespace=openshift-dns
    ...    OK: All DaemonSets status are ok | 'node-ca#daemonset.pods.desired.count'=1;;;; 'node-ca#daemonset.pods.current.count'=1;;;; 'node-ca#daemonset.pods.available.count'=1;;;; 'node-ca#daemonset.pods.uptodate.count'=1;;;; 'node-ca#daemonset.pods.ready.count'=1;;;; 'node-ca#daemonset.pods.misscheduled.count'=0;;;; 'node-ca#daemonset.pods.unavailable.count'=0;;;; 'csi-hostpathplugin#daemonset.pods.desired.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.current.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.available.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.uptodate.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.ready.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.misscheduled.count'=0;;;; 'csi-hostpathplugin#daemonset.pods.unavailable.count'=0;;;;
    ...    6
    ...    --warning-status='\\\%{desired} == 1'
    ...    WARNING: DaemonSet 'openshift-dns/dns-default' Pods Desired: 1, Current: 1, Available: 1, Unavailable: 0, Up-to-date: 1, Ready: 1, Misscheduled: 0 - DaemonSet 'openshift-dns/node-resolver' Pods Desired: 1, Current: 1, Available: 1, Unavailable: 0, Up-to-date: 1, Ready: 1, Misscheduled: 0 - DaemonSet 'openshift-image-registry/node-ca' Pods Desired: 1, Current: 1, Available: 1, Unavailable: 0, Up-to-date: 1, Ready: 1, Misscheduled: 0 - DaemonSet 'hostpath-provisioner/csi-hostpathplugin' Pods Desired: 1, Current: 1, Available: 1, Unavailable: 0, Up-to-date: 1, Ready: 1, Misscheduled: 0 | 'dns-default#daemonset.pods.desired.count'=1;;;; 'dns-default#daemonset.pods.current.count'=1;;;; 'dns-default#daemonset.pods.available.count'=1;;;; 'dns-default#daemonset.pods.uptodate.count'=1;;;; 'dns-default#daemonset.pods.ready.count'=1;;;; 'dns-default#daemonset.pods.misscheduled.count'=0;;;; 'dns-default#daemonset.pods.unavailable.count'=0;;;; 'node-resolver#daemonset.pods.desired.count'=1;;;; 'node-resolver#daemonset.pods.current.count'=1;;;; 'node-resolver#daemonset.pods.available.count'=1;;;; 'node-resolver#daemonset.pods.uptodate.count'=1;;;; 'node-resolver#daemonset.pods.ready.count'=1;;;; 'node-resolver#daemonset.pods.misscheduled.count'=0;;;; 'node-resolver#daemonset.pods.unavailable.count'=0;;;; 'node-ca#daemonset.pods.desired.count'=1;;;; 'node-ca#daemonset.pods.current.count'=1;;;; 'node-ca#daemonset.pods.available.count'=1;;;; 'node-ca#daemonset.pods.uptodate.count'=1;;;; 'node-ca#daemonset.pods.ready.count'=1;;;; 'node-ca#daemonset.pods.misscheduled.count'=0;;;; 'node-ca#daemonset.pods.unavailable.count'=0;;;; 'csi-hostpathplugin#daemonset.pods.desired.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.current.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.available.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.uptodate.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.ready.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.misscheduled.count'=0;;;; 'csi-hostpathplugin#daemonset.pods.unavailable.count'=0;;;;
    ...    7
    ...    --critical-status='\\\%{desired} == 1'
    ...    CRITICAL: DaemonSet 'openshift-dns/dns-default' Pods Desired: 1, Current: 1, Available: 1, Unavailable: 0, Up-to-date: 1, Ready: 1, Misscheduled: 0 - DaemonSet 'openshift-dns/node-resolver' Pods Desired: 1, Current: 1, Available: 1, Unavailable: 0, Up-to-date: 1, Ready: 1, Misscheduled: 0 - DaemonSet 'openshift-image-registry/node-ca' Pods Desired: 1, Current: 1, Available: 1, Unavailable: 0, Up-to-date: 1, Ready: 1, Misscheduled: 0 - DaemonSet 'hostpath-provisioner/csi-hostpathplugin' Pods Desired: 1, Current: 1, Available: 1, Unavailable: 0, Up-to-date: 1, Ready: 1, Misscheduled: 0 | 'dns-default#daemonset.pods.desired.count'=1;;;; 'dns-default#daemonset.pods.current.count'=1;;;; 'dns-default#daemonset.pods.available.count'=1;;;; 'dns-default#daemonset.pods.uptodate.count'=1;;;; 'dns-default#daemonset.pods.ready.count'=1;;;; 'dns-default#daemonset.pods.misscheduled.count'=0;;;; 'dns-default#daemonset.pods.unavailable.count'=0;;;; 'node-resolver#daemonset.pods.desired.count'=1;;;; 'node-resolver#daemonset.pods.current.count'=1;;;; 'node-resolver#daemonset.pods.available.count'=1;;;; 'node-resolver#daemonset.pods.uptodate.count'=1;;;; 'node-resolver#daemonset.pods.ready.count'=1;;;; 'node-resolver#daemonset.pods.misscheduled.count'=0;;;; 'node-resolver#daemonset.pods.unavailable.count'=0;;;; 'node-ca#daemonset.pods.desired.count'=1;;;; 'node-ca#daemonset.pods.current.count'=1;;;; 'node-ca#daemonset.pods.available.count'=1;;;; 'node-ca#daemonset.pods.uptodate.count'=1;;;; 'node-ca#daemonset.pods.ready.count'=1;;;; 'node-ca#daemonset.pods.misscheduled.count'=0;;;; 'node-ca#daemonset.pods.unavailable.count'=0;;;; 'csi-hostpathplugin#daemonset.pods.desired.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.current.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.available.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.uptodate.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.ready.count'=1;;;; 'csi-hostpathplugin#daemonset.pods.misscheduled.count'=0;;;; 'csi-hostpathplugin#daemonset.pods.unavailable.count'=0;;;;
