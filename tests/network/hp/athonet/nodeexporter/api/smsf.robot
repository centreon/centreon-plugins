*** Settings ***
Documentation       HP Athonet Node Exporter plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}mockoon.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${CMD}                  ${CENTREON_PLUGINS} --plugin=network::hp::athonet::nodeexporter::api::plugin --mode=smsf --hostname=${HOSTNAME} --port=${APIPORT} --proto http --api-username=1 --api-password=1



*** Test Cases ***
SMSF (Short Message Service Function) ${tc}
    [Tags]    network    hp    api


    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                                                            expected_result    --
            ...       1   ${EMPTY}                                                                 OK: Number of SMS messages stored: 0 - All diameter connections are ok | 'smsf.sms.stored.count'=0;;;0;
            ...       2   --unknown-diameter-connection-status='%\\{status\\} !~ /down/i'          UNKNOWN: diameter stack 'default' origin host 'site1-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up - diameter stack 'default' origin host 'site2-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up | 'smsf.sms.stored.count'=0;;;0;
            ...       3   --warning-diameter-connection-status='%\\{status\\} !~ /down/i'          WARNING: diameter stack 'default' origin host 'site1-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up - diameter stack 'default' origin host 'site2-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up | 'smsf.sms.stored.count'=0;;;0;
            ...       4   --critical-diameter-connection-status='%\\{status\\} !~ /down/i'         CRITICAL: diameter stack 'default' origin host 'site1-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up - diameter stack 'default' origin host 'site2-dra01-local.bjo.fgh123.klm567.domain.local' connection status: up | 'smsf.sms.stored.count'=0;;;0;
            ...       5   --warning-sms-stored=1:                                                  WARNING: Number of SMS messages stored: 0 | 'smsf.sms.stored.count'=0;1:;;0;
            ...       6   --critical-sms-stored=1:                                                 CRITICAL: Number of SMS messages stored: 0 | 'smsf.sms.stored.count'=0;;1:;0;
