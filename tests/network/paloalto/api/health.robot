*** Settings ***
Documentation       network::paloalto::api::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon-paloalto-api.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=network::paloalto::api::plugin
...                 --mode=health
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --auth-type=api-key
...                 --api-key=D@pAs$W@rD


*** Test Cases ***
Health ${tc}
    [Tags]    network    paloalto    api

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
    ...    ${EMPTY}
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    2
    ...    --filter-counters=1
    ...    OK:
    ...    3
    ...    --include-device-serial=1
    ...    OK: Panorama total devices: 0, connected devices: 0, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 | 'panorama.devices.total.count'=0;;;0; 'panorama.devices.connected.count'=0;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    4
    ...    --exclude-device-serial=1
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    5
    ...    --include-device-hostname=1
    ...    OK: Panorama total devices: 0, connected devices: 0, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 | 'panorama.devices.total.count'=0;;;0; 'panorama.devices.connected.count'=0;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    6
    ...    --critical-missing-plugin=1
    ...    CRITICAL: plugin '1' was missing ! | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    7
    ...    --warning-missing-plugin=1
    ...    WARNING: plugin '1' was missing ! | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    8
    ...    --exclude-device-hostname=1
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    9
    ...    --include-plugin=1
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    10
    ...    --exclude-plugin=1
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    11
    ...    --include-template=1
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    12
    ...    --exclude-template=1
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    13
    ...    --include-job-type=1
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    14
    ...    --exclude-job-type=1
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    15
    ...    --truncate-jobs-warnings=1
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    16
    ...    --connected-only=1
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    17
    ...    --unknown-device-connection-status=1
    ...    UNKNOWN: device 'fw-london.example.com' (FW-LONDON) connected: yes - device 'fw-nyc.example.com' (FW-NYC) connected: yes - device 'fw-tokyo.example.com' (FW-TOKYO) connected: yes | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    18
    ...    --warning-device-connection-status=1
    ...    WARNING: device 'fw-london.example.com' (FW-LONDON) connected: yes - device 'fw-nyc.example.com' (FW-NYC) connected: yes - device 'fw-tokyo.example.com' (FW-TOKYO) connected: yes | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    19
    ...    --critical-device-connection-status=1
    ...    CRITICAL: device 'fw-london.example.com' (FW-LONDON) connected: yes - device 'fw-nyc.example.com' (FW-NYC) connected: yes - device 'fw-tokyo.example.com' (FW-TOKYO) connected: yes | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    20
    ...    --unknown-device-software-version=1
    ...    UNKNOWN: device 'fw-london.example.com' (FW-LONDON) software version: 10.0.5 - device 'fw-nyc.example.com' (FW-NYC) software version: 10.1.3 - device 'fw-tokyo.example.com' (FW-TOKYO) software version: 10.1.1 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    21
    ...    --warning-device-software-version=1
    ...    WARNING: device 'fw-london.example.com' (FW-LONDON) software version: 10.0.5 - device 'fw-nyc.example.com' (FW-NYC) software version: 10.1.3 - device 'fw-tokyo.example.com' (FW-TOKYO) software version: 10.1.1 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    22
    ...    --critical-device-software-version=1
    ...    CRITICAL: device 'fw-london.example.com' (FW-LONDON) software version: 10.0.5 - device 'fw-nyc.example.com' (FW-NYC) software version: 10.1.3 - device 'fw-tokyo.example.com' (FW-TOKYO) software version: 10.1.1 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    23
    ...    --unknown-device-ha-state=1
    ...    UNKNOWN: device 'fw-london.example.com' (FW-LONDON) HA state: unknown - device 'fw-nyc.example.com' (FW-NYC) HA state: unknown - device 'fw-tokyo.example.com' (FW-TOKYO) HA state: unknown | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    24
    ...    --warning-device-ha-state=1
    ...    WARNING: device 'fw-london.example.com' (FW-LONDON) HA state: unknown - device 'fw-nyc.example.com' (FW-NYC) HA state: unknown - device 'fw-tokyo.example.com' (FW-TOKYO) HA state: unknown | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    25
    ...    --critical-device-ha-state=1
    ...    CRITICAL: device 'fw-london.example.com' (FW-LONDON) HA state: unknown - device 'fw-nyc.example.com' (FW-NYC) HA state: unknown - device 'fw-tokyo.example.com' (FW-TOKYO) HA state: unknown | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    26
    ...    --include-device-serial=FW-LONDON
    ...    OK: Panorama total devices: 1, connected devices: 1, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - device 'fw-london.example.com' (FW-LONDON) connected: yes, HA state: unknown | 'panorama.devices.total.count'=1;;;0; 'panorama.devices.connected.count'=1;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    27
    ...    --exclude-device-serial=FW-LONDON
    ...    OK: Panorama total devices: 2, connected devices: 2, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=2;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    28
    ...    --include-device-hostname=fw-london
    ...    OK: Panorama total devices: 1, connected devices: 1, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - device 'fw-london.example.com' (FW-LONDON) connected: yes, HA state: unknown | 'panorama.devices.total.count'=1;;;0; 'panorama.devices.connected.count'=1;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    29
    ...    --exclude-device-hostname=fw-london
    ...    OK: Panorama total devices: 2, connected devices: 2, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=2;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    30
    ...    --include-plugin=dlp
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    31
    ...    --exclude-plugin=dlp
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    32
    ...    --include-template=test
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    33
    ...    --exclude-template=test
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    34
    ...    --include-job-type=Commit
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    35
    ...    --exclude-job-type=Commit
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    36
    ...    --warning-devices-total=1:
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;1:;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    37
    ...    --critical-devices-total=1:
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;1:;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    38
    ...    --warning-devices-connected=1:
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;1:;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    39
    ...    --critical-devices-connected=1:
    ...    OK: Panorama total devices: 3, connected devices: 3, total templates: 0, template assignments: 0, plugins checked: 0, jobs checked: 0 - All devices are ok | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;1:;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    40
    ...    --warning-templates-total=1:
    ...    WARNING: Panorama total templates: 0 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;1:;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    41
    ...    --critical-templates-total=1:
    ...    CRITICAL: Panorama total templates: 0 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;1:;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    42
    ...    --warning-templates-assigned=1:
    ...    WARNING: Panorama template assignments: 0 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;1:;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    43
    ...    --critical-templates-assigned=1:
    ...    CRITICAL: Panorama template assignments: 0 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;1:;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    44
    ...    --warning-plugins-total=1:
    ...    WARNING: Panorama plugins checked: 0 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;1:;;0; 'panorama.jobs.total.count'=0;;;0;
    ...    45
    ...    --critical-plugins-total=1:
    ...    CRITICAL: Panorama plugins checked: 0 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;1:;0; 'panorama.jobs.total.count'=0;;;0;
    ...    46
    ...    --warning-jobs-total=1:
    ...    WARNING: Panorama jobs checked: 0 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;1:;;0;
    ...    47
    ...    --critical-jobs-total=1:
    ...    CRITICAL: Panorama jobs checked: 0 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=3;;;0; 'panorama.templates.total.count'=0;;;0; 'panorama.templates.assigned.count'=0;;;0; 'panorama.plugins.total.count'=0;;;0; 'panorama.jobs.total.count'=0;;1:;0;
