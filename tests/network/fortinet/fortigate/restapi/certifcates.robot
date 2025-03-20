*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}certificates.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=network::fortinet::fortigate::restapi::plugin
...                 --mode=certificates
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --access-token=mokoon-token
...                 --port=${APIPORT}

*** Test Cases ***
certificates ${tc}
    [Tags]    network    fortinet    fortigate    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}
 

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:         tc      extra_options                                                                    expected_result    --
            ...       1       --filter-name='Fortinet_CA_SSL'                                                  OK: All certificates are ok | 'Fortinet_CA_SSL#certificate.expires.seconds=\d+;;;0; 'Fortinet_CA_SSL1#certificate.expires.seconds=\d+;;;0; 'Fortinet_CA_SSL2#certificate.expires.seconds=\d+;;;0;
            ...       2       --warning-status='\\\%{status} =~ /valid/i'                                      WARNING: Certificate 'Fortinet_CA_SSL' status: valid - Certificate 'Fortinet_CA_SSL1' status: valid - Certificate 'Fortinet_CA_SSL2' status: valid | 'Fortinet_CA_SSL#certificate.expires.seconds'=61673374s;;;0; 'Fortinet_CA_SSL1#certificate.expires.seconds'=209570627s;;;0; 'Fortinet_CA_SSL2#certificate.expires.seconds'=61673369s;;;0;
            ...       3       --critical-status='\\\%{status} =~ /valid/i'                                     CRITICAL: Certificate 'Fortinet_CA_SSL' status: valid - Certificate 'Fortinet_CA_SSL1' status: valid - Certificate 'Fortinet_CA_SSL2' status: valid | 'Fortinet_CA_SSL#certificate.expires.seconds'=61672471s;;;0; 'Fortinet_CA_SSL1#certificate.expires.seconds'=209569724s;;;0; 'Fortinet_CA_SSL2#certificate.expires.seconds'=61672466s;;;0;
            ...       4       --unit='m'                                                                       OK: All certificates are ok | 'Fortinet_CA_SSL#certificate.expires.minutes'=1027896m;;;0; 'Fortinet_CA_SSL1#certificate.expires.minutes'=3492850m;;;0; 'Fortinet_CA_SSL2#certificate.expires.minutes'=1027896m;;;0;
            ...       5       --warning-expires='60' --critical-expires='30' --unit='d'                        CRITICAL: Certificate 'Fortinet_CA_SSL' expires in 1y 11M 1w 6d 18h 28m 8s - Certificate 'Fortinet_CA_SSL1' expires in 6y 7M 3w 1h 54m 43s - Certificate 'Fortinet_CA_SSL2' expires in 1y 11M 1w 6d 18h 28m 3s | 'Fortinet_CA_SSL#certificate.expires.days'=713d;0:60;0:30;0; 'Fortinet_CA_SSL1#certificate.expires.days'=2425d;0:60;0:30;0; 'Fortinet_CA_SSL2#certificate.expires.days'=713d;0:60;0:30;0; 