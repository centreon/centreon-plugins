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
...                 --keystone-url=http://${HOSTNAME}:${APIPORT}  
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

    Examples:        tc       extraoptions                                                                                                                     expected_string    --
           ...       1        ${EMPTY}                                                                                                                         OK: 21 endpoints responded - All services are ok | 'endpoints.count.total'=21;;1:;0;
           ...       2        --service-url=http://localhost:3010/glance --include-type=image --include-name=glance                                            OK: 1 endpoints responded - Service [glance] [image] responded with HTTP 200 on http://localhost:3010/glance | 'endpoints.count.total'=1;;1:;0;
           ...       3        --service-url=http://localhost:3010/horizon --include-type=dashboard --include-name=horizon                                      OK: 1 endpoints responded - Service [horizon] [dashboard] responded with HTTP 200 on http://localhost:3010/horizon | 'endpoints.count.total'=1;;1:;0;
           ...       4        --service-url=http://localhost:3010/error                                                                                        CRITICAL: Service [N/A] [service] responded invalid content with HTTP 404 on http://localhost:3010/error | 'endpoints.count.total'=1;;1:;0; 
           ...       5        --service-url=http://localhost:3010/glance --include-type=image --warning-status='%\\\{http_status\\\} =~ /200/'                 WARNING: Service [N/A] [image] responded with HTTP 200 on http://localhost:3010/glance | 'endpoints.count.total'=1;;1:;0;
