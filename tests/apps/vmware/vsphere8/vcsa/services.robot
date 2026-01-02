*** Settings ***
Documentation       apps::vmware::vsphere8::vcsa::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...         --plugin=apps::vmware::vsphere8::vcsa::plugin
...         --mode=services
...         --hostname=${HOSTNAME}
...         --port=${APIPORT}
...         --proto=http
...         --username=1
...         --password=1


*** Test Cases ***
Services ${tc}
    [Tags]    apps    vmware    vcsa
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
    ...    --exclude-id=.*
    ...    UNKNOWN: No service found with current filters.
    ...    2
    ...    --service-id=observability
    ...    OK: service 'observability' (observability.service) is 'STARTED'
    ...    3
    ...    --include-id='(observability\\\|vmware-pod)'
    ...    OK: All services are OK
    ...    4
    ...    --exclude-id=[aeu]
    ...    CRITICAL: service 'initrd-switch-root' (Switch Root) is 'STOPPED'
    ...    5
    ...    --include-description=Expecttls
    ...    CRITICAL: service 'vmware-expecttls' (Vmware Expecttls daemon) is 'STOPPED'
    ...    6
    ...    --exclude-description=[aeu]
    ...    CRITICAL: service 'initrd-switch-root' (Switch Root) is 'STOPPED'
    ...    7
    ...    --critical-status=0 --exclude-description=[aeu]
    ...    WARNING: service 'initrd-switch-root' (Switch Root) is 'STOPPED'
