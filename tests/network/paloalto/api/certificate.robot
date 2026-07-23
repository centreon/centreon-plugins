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

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_regexp}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_regexp
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All device certificates are OK | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=623d;;;0;
    ...    2
    ...    --filter-counters=certificate
    ...    OK: All device certificates are OK | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=623d;;;0;
    ...    3
    ...    --include-device-serial=LON
    ...    OK: Device 'fw-london.example.com' (FW-LONDON) certificate status: Valid, expires in: 61 days | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0;
    ...    4
    ...    --exclude-device-serial=TOK
    ...    OK: All device certificates are OK | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;;0;
    ...    5
    ...    --include-device-hostname='london'
    ...    OK: Device 'fw-london.example.com' (FW-LONDON) certificate status: Valid, expires in: 61 days | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0;
    ...    6
    ...    --exclude-device-hostname='fw-tokyo.example.com'
    ...    OK: All device certificates are OK | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;;0;
    ...    7
    ...    --connected-only=1
    ...    OK: All device certificates are OK | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=623d;;;0;
    ...    8
    ...    --unknown-certificate-status="\\\%{cert_status} ne ''" --critical-certificate-status=
    ...    UNKNOWN: Device 'fw-london.example.com' (FW-LONDON) certificate status: Valid - Device 'fw-nyc.example.com' (FW-NYC) certificate status: Valid - Device 'fw-tokyo.example.com' (FW-TOKYO) certificate status: Valid | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=623d;;;0;
    ...    9
    ...    --warning-certificate-status="\\\%{cert_status} ne ''" --critical-certificate-status=
    ...    WARNING: Device 'fw-london.example.com' (FW-LONDON) certificate status: Valid - Device 'fw-nyc.example.com' (FW-NYC) certificate status: Valid - Device 'fw-tokyo.example.com' (FW-TOKYO) certificate status: Valid | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=623d;;;0;
    ...    10
    ...    --critical-certificate-status="\\\%{cert_status} ne ''"
    ...    CRITICAL: Device 'fw-london.example.com' (FW-LONDON) certificate status: Valid - Device 'fw-nyc.example.com' (FW-NYC) certificate status: Valid - Device 'fw-tokyo.example.com' (FW-TOKYO) certificate status: Valid | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=623d;;;0;
    ...    11
    ...    --unknown-certificate-subject=1 --critical-certificate-status=
    ...    UNKNOWN: Device 'fw-london.example.com' (FW-LONDON) subject: - Device 'fw-nyc.example.com' (FW-NYC) subject: - Device 'fw-tokyo.example.com' (FW-TOKYO) subject: | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=623d;;;0;
    ...    12
    ...    --warning-certificate-subject=1 --critical-certificate-status=
    ...    WARNING: Device 'fw-london.example.com' (FW-LONDON) subject: - Device 'fw-nyc.example.com' (FW-NYC) subject: - Device 'fw-tokyo.example.com' (FW-TOKYO) subject: | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=623d;;;0;
    ...    13
    ...    --critical-certificate-subject=1 --critical-certificate-status=
    ...    CRITICAL: Device 'fw-london.example.com' (FW-LONDON) subject: - Device 'fw-nyc.example.com' (FW-NYC) subject: - Device 'fw-tokyo.example.com' (FW-TOKYO) subject: | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=623d;;;0;
    ...    14
    ...    --warning-certificate-expiry=1 --critical-certificate-status=
    ...    WARNING: Device 'fw-london.example.com' (FW-LONDON) expires in: 61 days - Device 'fw-nyc.example.com' (FW-NYC) expires in: 623 days - Device 'fw-tokyo.example.com' (FW-TOKYO) expires in: 623 days | 'fw-london.example.com#device.certificate.expiry.days'=61d;0:1;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;0:1;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=623d;0:1;;0;
    ...    15
    ...    --critical-certificate-expiry=1 --critical-certificate-status=
    ...    CRITICAL: Device 'fw-london.example.com' (FW-LONDON) expires in: 61 days - Device 'fw-nyc.example.com' (FW-NYC) expires in: 623 days - Device 'fw-tokyo.example.com' (FW-TOKYO) expires in: 623 days | 'fw-london.example.com#device.certificate.expiry.days'=61d;;0:1;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;0:1;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=623d;;0:1;0;
    ...    16
    ...    --unknown-certificate-custom-usage=1 --critical-certificate-status=
    ...    UNKNOWN: Device 'fw-london.example.com' (FW-LONDON) custom certificate usage: yes - Device 'fw-nyc.example.com' (FW-NYC) custom certificate usage: no - Device 'fw-tokyo.example.com' (FW-TOKYO) custom certificate usage: no | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=623d;;;0;
    ...    17
    ...    --warning-certificate-custom-usage=1 --critical-certificate-status=
    ...    WARNING: Device 'fw-london.example.com' (FW-LONDON) custom certificate usage: yes - Device 'fw-nyc.example.com' (FW-NYC) custom certificate usage: no - Device 'fw-tokyo.example.com' (FW-TOKYO) custom certificate usage: no | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=623d;;;0;
    ...    18
    ...    --critical-certificate-custom-usage=1 --critical-certificate-status=
    ...    CRITICAL: Device 'fw-london.example.com' (FW-LONDON) custom certificate usage: yes - Device 'fw-nyc.example.com' (FW-NYC) custom certificate usage: no - Device 'fw-tokyo.example.com' (FW-TOKYO) custom certificate usage: no | 'fw-london.example.com#device.certificate.expiry.days'=61d;;;0; 'fw-nyc.example.com#device.certificate.expiry.days'=623d;;;0; 'fw-tokyo.example.com#device.certificate.expiry.days'=623d;;;0;
