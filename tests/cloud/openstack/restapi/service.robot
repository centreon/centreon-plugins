*** Settings ***
Documentation       OpenStack Service

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}openstack.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=cloud::openstack::restapi::plugin
...                 --identity-url=http://${HOSTNAME}:${APIPORT}/v3
...                 --mode=service
...                 --username=xxx
...                 --password=P@s$WoRdZ


*** Test Cases ***
Service ${tc}
    [Tags]    cloud     openstack     api
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_string}

    Examples:        tc       extraoptions                                                                                                                             expected_string    --
           ...       1        --filter-counters=count                                                                                                                  OK: 21 endpoints responded | 'endpoints.count.total'=21;;1:;0;
           ...       2        --service-url=http://${HOSTNAME}:${APIPORT}/glance --include-service-type=image --include-service-name=glance                            OK: 1 endpoints responded - Service [glance] [image] responded with HTTP 200 on http://${HOSTNAME}:${APIPORT}/glance | 'endpoints.count.total'=1;;1:;0;
           ...       3        --service-url=http://${HOSTNAME}:${APIPORT}/horizon --include-service-type=dashboard --include-service-name=horizon                      OK: 1 endpoints responded - Service [horizon] [dashboard] responded with HTTP 200 on http://${HOSTNAME}:${APIPORT}/horizon | 'endpoints.count.total'=1;;1:;0;
           ...       4        --service-url=http://${HOSTNAME}:${APIPORT}/error                                                                                        CRITICAL: Service [N/A] [service] responded invalid content with HTTP 404 on http://${HOSTNAME}:${APIPORT}/error | 'endpoints.count.total'=1;;1:;0;
           ...       5        --service-url=http://${HOSTNAME}:${APIPORT}/glance --include-service-type=image --warning-status='%\\\{http_status\\\} =~ /200/'         WARNING: Service [N/A] [image] responded with HTTP 200 on http://${HOSTNAME}:${APIPORT}/glance | 'endpoints.count.total'=1;;1:;0;
