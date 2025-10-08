*** Settings ***
Documentation       Cloud Microsoft Office365 Management API Mode Service Status

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}office365.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=cloud::microsoft::office365::management::plugin
...                 --tenant='our-tenant'
...                 --client-id=our-client-id
...                 --client-secret=client-secret
...                 --login-endpoint=http://${HOSTNAME}:${APIPORT}
...                 --graph-endpoint=http://${HOSTNAME}:${APIPORT}

*** Test Cases ***
ServiceStatus ${tc}
    [Tags]    cloud    microsoft    office365    api
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=service-status
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:        tc       extraoptions                                                                                expected_regexp    --
            ...      1        ${EMPTY}                                                                                    ^CRITICAL: Service 'Microsoft Teams' status is 'serviceDegradation'
            ...      2        --warning-status='\\\%{status} =~ /serviceDegradation/i' --critical-status=''               ^WARNING: Service 'Microsoft Teams' status is 'serviceDegradation'
            ...      3        --include-service-name='SharePoint'                                                         OK: Service 'SharePoint Online' status is 'serviceOperational'
            ...      4        --exclude-service-name='Teams'                                                              OK: All services are ok
            ...      5        --include-classification=Unknown                                                            UNKNOWN: No services found.
            ...      6        --exclude-classification=Incident                                                           CRITICAL: Service 'Microsoft Teams' status is 'serviceDegradation' \\\\[issue: advisory, ABCDEF-02, 2025-09-30T07:15:00Z, un deuxieme\\\\]
