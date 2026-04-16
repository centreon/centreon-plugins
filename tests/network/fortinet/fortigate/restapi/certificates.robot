*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
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
            ...       1       --filter-name='Fortinet_CA_SSL'                                                  OK: All certificates are ok \\\| 'Fortinet_CA_SSL#certificate.expires.seconds=\\\d+;;;0; 'Fortinet_CA_SSL1#certificate.expires.seconds=\\\d+;;;0; 'Fortinet_CA_SSL2#certificate.expires.seconds=\\\d+;;;0;
            ...       2       --warning-status='\\\%{status} =~ /valid/i'                                      WARNING: Certificate 'Fortinet_CA_SSL' status: valid - Certificate 'Fortinet_CA_SSL1' status: valid - Certificate 'Fortinet_CA_SSL2' status: valid \\\| 'Fortinet_CA_SSL#certificate.expires.seconds'=\d+;;;0; 'Fortinet_CA_SSL1#certificate.expires.seconds'=\d+;;;0; 'Fortinet_CA_SSL2#certificate.expires.seconds'=\d+;;;0;
            ...       3       --critical-status='\\\%{status} =~ /valid/i'                                     CRITICAL: Certificate 'Fortinet_CA_SSL' status: valid - Certificate 'Fortinet_CA_SSL1' status: valid - Certificate 'Fortinet_CA_SSL2' status: valid \\\| 'Fortinet_CA_SSL#certificate.expires.seconds'=\d+;;;0; 'Fortinet_CA_SSL1#certificate.expires.seconds'=\d+;;;0; 'Fortinet_CA_SSL2#certificate.expires.seconds'=\d+;;;0;
            ...       4       --unit='m'                                                                       OK: All certificates are ok \\\| 'Fortinet_CA_SSL#certificate.expires.minutes'=\d+;;;0; 'Fortinet_CA_SSL1#certificate.expires.minutes'=\d+;;;0; 'Fortinet_CA_SSL2#certificate.expires.minutes'=\d+;;;0;
            ...       5       --warning-expires='60' --critical-expires='30' --unit='d'                        CRITICAL: Certificate 'Fortinet_CA_SSL' expires in (\\\\d+y)?\\\\s?(\\\\d+M)?\\\\s?(\\\\d+w)?\\\\s?(\\\\d+d)?\\\\s?(\\\\d+h)?\\\\s?(\\\\d+m)?\\\\s?(\\\\d+s)? - Certificate 'Fortinet_CA_SSL1' expires in (\\\\d+y)?\\\\s?(\\\\d+M)?\\\\s?(\\\\d+w)?\\\\s?(\\\\d+d)?\\\\s?(\\\\d+h)?\\\\s?(\\\\d+m)?\\\\s?(\\\\d+s)? - Certificate 'Fortinet_CA_SSL2' expires in (\\\\d+y)?\\\\s?(\\\\d+M)?\\\\s?(\\\\d+w)?\\\\s?(\\\\d+d)?\\\\s?(\\\\d+h)?\\\\s?(\\\\d+m)?\\\\s?(\\\\d+s)? \\\| 'Fortinet_CA_SSL#certificate.expires.days'=\d+;0:60;0:30;0; 'Fortinet_CA_SSL1#certificate.expires.days'=\d+;0:60;0:30;0; 'Fortinet_CA_SSL2#certificate.expires.days'=\d+;0:60;0:30;0;
