*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s
Test Setup          Ctn Cleanup Cache

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vm::plugin
...                 --mode=vm-tools
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000

*** Test Cases ***
Vm-Tools ${tc}
    [Tags]    apps    api    vmware   vsphere8    vm
    ${command}    Catenate    ${CMD} ${filter_vm} ${extraoptions}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}
    
    
    Examples:    tc     filter_vm                   extraoptions                      expected_result   --
        ...      1     --vm-name=db-server-01       ${EMPTY}                          OK: vm-7722 had 1 install attempts - version is UNMANAGED (v12.2.0) - updates are MANUAL (auto-updates not allowed) - tools are RUNNING | 'tools.install.attempts.count'=1;;;0;
        ...      2     --vm-name=web-server-01      ${EMPTY}                          OK: vm-7657 had 4 install attempts - version is CURRENT (v12.3.0) - updates are MANUAL (auto-updates allowed) - tools are RUNNING | 'tools.install.attempts.count'=4;;;0;
        ...      3     --vm-name=web-server-02      ${EMPTY}                          WARNING: vm-1234 tools are NOT_RUNNING | 'tools.install.attempts.count'=4;;;0;
        ...      4     --vm-name=web-server-03      ${EMPTY}                          UNKNOWN: Cannot get VM ID from VM name 'web-server-03'
        ...      5     --vm-id=vm-7722              ${EMPTY}                          OK: vm-7722 had 1 install attempts - version is UNMANAGED (v12.2.0) - updates are MANUAL (auto-updates not allowed) - tools are RUNNING | 'tools.install.attempts.count'=1;;;0;
        ...      6     --vm-id=vm-7657              ${EMPTY}                          OK: vm-7657 had 4 install attempts - version is CURRENT (v12.3.0) - updates are MANUAL (auto-updates allowed) - tools are RUNNING | 'tools.install.attempts.count'=4;;;0;
        ...      7     --vm-id=vm-1234              ${EMPTY}                          WARNING: vm-1234 tools are NOT_RUNNING | 'tools.install.attempts.count'=4;;;0;
        ...      8     --vm-id=vm-3000000           ${EMPTY}                          UNKNOWN: API returns error of type NOT_FOUND: [Id: com.vmware.api.vcenter.vm.not_found - Msg: Virtual machine with identifier 'vm-3000000:c186dc36-76b6-4435-b5f3-cb1e9678a67e' does not exist. (vm-3000000:c186dc36-76b6-4435-b5f3-cb1e9678a67e)]
        ...      9     --vm-id=vm-7722              --warning-install-attempts=0      WARNING: vm-7722 had 1 install attempts | 'tools.install.attempts.count'=1;0:0;;0;
        ...      10    --vm-id=vm-7657              --warning-install-attempts=0      WARNING: vm-7657 had 4 install attempts | 'tools.install.attempts.count'=4;0:0;;0;
        ...      11    --vm-id=vm-1234              --warning-install-attempts=0      WARNING: vm-1234 had 4 install attempts (error messages available in long output with --verbose option) - tools are NOT_RUNNING | 'tools.install.attempts.count'=4;0:0;;0;
        ...      13    --vm-id=vm-7722              --critical-install-attempts=0     CRITICAL: vm-7722 had 1 install attempts | 'tools.install.attempts.count'=1;;0:0;0;
        ...      14    --vm-id=vm-7657              --critical-install-attempts=0     CRITICAL: vm-7657 had 4 install attempts | 'tools.install.attempts.count'=4;;0:0;0;
        ...      15    --vm-id=vm-1234              --critical-install-attempts=0     CRITICAL: vm-1234 had 4 install attempts (error messages available in long output with --verbose option) - tools are NOT_RUNNING | 'tools.install.attempts.count'=4;;0:0;0;
        ...      17    --vm-id=vm-7722              --warning-run-state=1             WARNING: vm-7722 tools are RUNNING | 'tools.install.attempts.count'=1;;;0;
        ...      18    --vm-id=vm-7657              --warning-run-state=1             WARNING: vm-7657 tools are RUNNING | 'tools.install.attempts.count'=4;;;0;
        ...      19    --vm-id=vm-1234              --warning-run-state=1             WARNING: vm-1234 tools are NOT_RUNNING | 'tools.install.attempts.count'=4;;;0;
        ...      21    --vm-id=vm-7722              --critical-run-state=1            CRITICAL: vm-7722 tools are RUNNING | 'tools.install.attempts.count'=1;;;0;
        ...      22    --vm-id=vm-7657              --critical-run-state=1            CRITICAL: vm-7657 tools are RUNNING | 'tools.install.attempts.count'=4;;;0;
        ...      23    --vm-id=vm-1234              --critical-run-state=1            CRITICAL: vm-1234 tools are NOT_RUNNING | 'tools.install.attempts.count'=4;;;0;
        ...      25    --vm-id=vm-7722              --warning-upgrade-policy=1        WARNING: vm-7722 updates are MANUAL (auto-updates not allowed) | 'tools.install.attempts.count'=1;;;0;
        ...      26    --vm-id=vm-7657              --warning-upgrade-policy=1        WARNING: vm-7657 updates are MANUAL (auto-updates allowed) | 'tools.install.attempts.count'=4;;;0;
        ...      27    --vm-id=vm-1234              --warning-upgrade-policy=1        WARNING: vm-1234 updates are MANUAL (auto-updates not allowed) - tools are NOT_RUNNING | 'tools.install.attempts.count'=4;;;0;
        ...      29    --vm-id=vm-7722              --critical-upgrade-policy=1       CRITICAL: vm-7722 updates are MANUAL (auto-updates not allowed) | 'tools.install.attempts.count'=1;;;0;
        ...      30    --vm-id=vm-7657              --critical-upgrade-policy=1       CRITICAL: vm-7657 updates are MANUAL (auto-updates allowed) | 'tools.install.attempts.count'=4;;;0;
        ...      31    --vm-id=vm-1234              --critical-upgrade-policy=1       CRITICAL: vm-1234 updates are MANUAL (auto-updates not allowed) - tools are NOT_RUNNING | 'tools.install.attempts.count'=4;;;0;
        ...      33    --vm-id=vm-7722              --warning-version-status=1        WARNING: vm-7722 version is UNMANAGED (v12.2.0) | 'tools.install.attempts.count'=1;;;0;
        ...      34    --vm-id=vm-7657              --warning-version-status=1        WARNING: vm-7657 version is CURRENT (v12.3.0) | 'tools.install.attempts.count'=4;;;0;
        ...      35    --vm-id=vm-1234              --warning-version-status=1        WARNING: vm-1234 version is CURRENT (v12.3.0) - tools are NOT_RUNNING | 'tools.install.attempts.count'=4;;;0;
        ...      37    --vm-id=vm-7722              --critical-version-status=1       CRITICAL: vm-7722 version is UNMANAGED (v12.2.0) | 'tools.install.attempts.count'=1;;;0;
        ...      38    --vm-id=vm-7657              --critical-version-status=1       CRITICAL: vm-7657 version is CURRENT (v12.3.0) | 'tools.install.attempts.count'=4;;;0;
        ...      39    --vm-id=vm-1234              --critical-version-status=1       CRITICAL: vm-1234 version is CURRENT (v12.3.0) - tools are NOT_RUNNING | 'tools.install.attempts.count'=4;;;0;
