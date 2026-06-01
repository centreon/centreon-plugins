*** Settings ***
Documentation       network::paloalto::api::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${INJECT_PERL}      -Mfixed_date -I${CURDIR}
${MOCKOON_JSON}     ${CURDIR}${/}mockoon-paloalto-api.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=network::paloalto::api::plugin
...                 --mode=certificate
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --auth-type=api-key
...                 --api-key=D@pAs$W@rD


*** Test Cases ***
Certificate ${tc}
    [Tags]    network    paloalto    api

    ${OLD_PERL5OPT}=    Get Environment Variable    PERL5OPT    default=
    Set Environment Variable    PERL5OPT    ${INJECT_PERL} ${OLD_PERL5OPT}

    ${command}=    Catenate
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
    ...    CRITICAL: Device 'fw-tokyo.example.com' (FW-TOKYO) certificate status: Expired | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=-388d;;;0;
    ...    2
    ...    --filter-counters=certificate
    ...    CRITICAL: Device 'fw-tokyo.example.com' (FW-TOKYO) certificate status: Expired | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=-388d;;;0;
    ...    3
    ...    --include-device-serial=LON
    ...    OK: Device 'fw-london.example.com' (FW-LONDON) certificate status: Valid, expires in: -316 days | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0;
    ...    4
    ...    --exclude-device-serial=TOK
    ...    OK: All device certificates are OK | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;;0;
    ...    5
    ...    --include-device-hostname='london'
    ...    OK: Device 'fw-london.example.com' (FW-LONDON) certificate status: Valid, expires in: -316 days | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0;
    ...    6
    ...    --exclude-device-hostname='fw-tokyo.example.com'
    ...    OK: All device certificates are OK | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;;0;
    ...    7
    ...    --connected-only=1
    ...    CRITICAL: Device 'fw-tokyo.example.com' (FW-TOKYO) certificate status: Expired | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=-388d;;;0;
    ...    8
    ...    --unknown-certificate-status='\\\%{cert_status}=~/Expired/' --critical-certificate-status=
    ...    UNKNOWN: Device 'fw-tokyo.example.com' (FW-TOKYO) certificate status: Expired | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=-388d;;;0;
    ...    9
    ...    --warning-certificate-status='\\\%{cert_status}=~/Expired/' --critical-certificate-status=
    ...    WARNING: Device 'fw-tokyo.example.com' (FW-TOKYO) certificate status: Expired | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=-388d;;;0;
    ...    10
    ...    --critical-certificate-status="\\\%{cert_status} ne ''"
    ...    CRITICAL: Device 'fw-london.example.com' (FW-LONDON) certificate status: Valid - Device 'fw-nyc.example.com' (FW-NYC) certificate status: Valid - Device 'fw-tokyo.example.com' (FW-TOKYO) certificate status: Expired | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=-388d;;;0;
    ...    11
    ...    --unknown-certificate-subject=1 --critical-certificate-status=
    ...    UNKNOWN: Device 'fw-london.example.com' (FW-LONDON) subject: CN=fw-london.example.com,O=Palo Alto Networks - Device 'fw-nyc.example.com' (FW-NYC) subject: CN=fw-nyc.example.com,O=Palo Alto Networks - Device 'fw-tokyo.example.com' (FW-TOKYO) subject: CN=fw-tokyo.example.com,O=Palo Alto Networks | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=-388d;;;0;
    ...    12
    ...    --warning-certificate-subject=1 --critical-certificate-status=
    ...    WARNING: Device 'fw-london.example.com' (FW-LONDON) subject: CN=fw-london.example.com,O=Palo Alto Networks - Device 'fw-nyc.example.com' (FW-NYC) subject: CN=fw-nyc.example.com,O=Palo Alto Networks - Device 'fw-tokyo.example.com' (FW-TOKYO) subject: CN=fw-tokyo.example.com,O=Palo Alto Networks | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=-388d;;;0;
    ...    13
    ...    --critical-certificate-subject=1 --critical-certificate-status=
    ...    CRITICAL: Device 'fw-london.example.com' (FW-LONDON) subject: CN=fw-london.example.com,O=Palo Alto Networks - Device 'fw-nyc.example.com' (FW-NYC) subject: CN=fw-nyc.example.com,O=Palo Alto Networks - Device 'fw-tokyo.example.com' (FW-TOKYO) subject: CN=fw-tokyo.example.com,O=Palo Alto Networks | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=-388d;;;0;
    ...    14
    ...    --warning-certificate-expiry=1 --critical-certificate-status=
    ...    WARNING: Device 'fw-london.example.com' (FW-LONDON) expires in: -316 days - Device 'fw-nyc.example.com' (FW-NYC) expires in: 317 days - Device 'fw-tokyo.example.com' (FW-TOKYO) expires in: -388 days | 'fw-london.example.com#device.certificate.expiry.days'=-316d;0:1;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;0:1;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=-388d;0:1;;0;
    ...    15
    ...    --critical-certificate-expiry=1 --critical-certificate-status=
    ...    CRITICAL: Device 'fw-london.example.com' (FW-LONDON) expires in: -316 days - Device 'fw-nyc.example.com' (FW-NYC) expires in: 317 days - Device 'fw-tokyo.example.com' (FW-TOKYO) expires in: -388 days | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;0:1;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;0:1;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=-388d;;0:1;0;
    ...    16
    ...    --unknown-certificate-custom-usage=1 --critical-certificate-status=
    ...    UNKNOWN: Device 'fw-london.example.com' (FW-LONDON) custom certificate usage: Yes - Device 'fw-nyc.example.com' (FW-NYC) custom certificate usage: No - Device 'fw-tokyo.example.com' (FW-TOKYO) custom certificate usage: No | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=-388d;;;0;
    ...    17
    ...    --warning-certificate-custom-usage=1 --critical-certificate-status=
    ...    WARNING: Device 'fw-london.example.com' (FW-LONDON) custom certificate usage: Yes - Device 'fw-nyc.example.com' (FW-NYC) custom certificate usage: No - Device 'fw-tokyo.example.com' (FW-TOKYO) custom certificate usage: No | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=-388d;;;0;
    ...    18
    ...    --critical-certificate-custom-usage=1 --critical-certificate-status=
    ...    CRITICAL: Device 'fw-london.example.com' (FW-LONDON) custom certificate usage: Yes - Device 'fw-nyc.example.com' (FW-NYC) custom certificate usage: No - Device 'fw-tokyo.example.com' (FW-TOKYO) custom certificate usage: No | 'fw-london.example.com#device.certificate.expiry.days'=-316d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=317d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=-388d;;;0;
