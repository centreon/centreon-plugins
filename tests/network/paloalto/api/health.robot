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
...                 --mode=health
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --auth-type=api-key
...                 --api-key=D@pAs$W@rD


*** Test Cases ***
Health ${tc}
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
    ...    CRITICAL: device 'fw-tokyo.example.com' (FW-TOKYO) connected: no - plugin 'vmware' status: failed (version: 1.5.2) - template-assignment 'FW-TOKYO' template: template-dev, vsys: vsys1, status: unknown - template-assignment 'FW-LONDON' template: template-prod, vsys: vsys1, status: out of sync | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    2
    ...    --filter-counters=template
    ...    CRITICAL: template-assignment 'FW-TOKYO' template: template-dev, vsys: vsys1, status: unknown - template-assignment 'FW-LONDON' template: template-prod, vsys: vsys1, status: out of sync | 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0;
    ...    3
    ...    --include-device-hostname=toky --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    OK: Panorama total devices: 1, connected devices: 0, out of sync devices: 0, total device-groups: 0, total templates: 2, template assignments: 3, template assignments out of sync: 2, last push status: OK, last push age: 4029270 seconds - device 'fw-tokyo.example.com' (FW-TOKYO) connected: no - All plugins are ok - All templates are ok - All template assignments are synchronized | 'panorama.devices.total.count'=1;;;0; 'panorama.devices.connected.count'=0;;;0; 'panorama.devices.out_of_sync.count'=0;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=2;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    4
    ...    --exclude-device-hostname=toky --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    OK: Panorama total devices: 2, connected devices: 2, out of sync devices: 1, total device-groups: 0, total templates: 2, template assignments: 3, template assignments out of sync: 2, last push status: OK, last push age: 4029270 seconds - All devices are ok - All plugins are ok - All templates are ok - All template assignments are synchronized | 'panorama.devices.total.count'=2;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=2;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    5
    ...    --include-device-serial=LONDO --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    OK: Panorama total devices: 1, connected devices: 1, out of sync devices: 1, total device-groups: 0, total templates: 2, template assignments: 3, template assignments out of sync: 3, last push status: OK, last push age: 4029270 seconds - device 'fw-london.example.com' (FW-LONDON) connected: yes - All plugins are ok - All templates are ok - All template assignments are synchronized | 'panorama.devices.total.count'=1;;;0; 'panorama.devices.connected.count'=1;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=3;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    6
    ...    --exclude-device-serial=LONDO --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    OK: Panorama total devices: 2, connected devices: 1, out of sync devices: 0, total device-groups: 0, total templates: 2, template assignments: 3, template assignments out of sync: 1, last push status: OK, last push age: 4029270 seconds - All devices are ok - All plugins are ok - All templates are ok - All template assignments are synchronized | 'panorama.devices.total.count'=2;;;0; 'panorama.devices.connected.count'=1;;;0; 'panorama.devices.out_of_sync.count'=0;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    7
    ...    --include-plugin=cisco --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    OK: Panorama total devices: 3, connected devices: 2, out of sync devices: 1, total device-groups: 0, total templates: 2, template assignments: 3, template assignments out of sync: 1, last push status: OK, last push age: 4029270 seconds - All devices are ok - plugin 'cisco' status: success (version: 2.1.0) - All templates are ok - All template assignments are synchronized | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    8
    ...    --exclude-plugin=cisco --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    OK: Panorama total devices: 3, connected devices: 2, out of sync devices: 1, total device-groups: 0, total templates: 2, template assignments: 3, template assignments out of sync: 1, last push status: OK, last push age: 4029270 seconds - All devices are ok - All plugins are ok - All templates are ok - All template assignments are synchronized | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    9
    ...    --include-template=dev --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    OK: Panorama total devices: 3, connected devices: 2, out of sync devices: 1, total device-groups: 0, total templates: 1, template assignments: 1, template assignments out of sync: 0, last push status: OK, last push age: 4029270 seconds - All devices are ok - All plugins are ok - template 'template-dev' template-devices-count : skipped (no value(s)) - template-assignment 'FW-TOKYO' template: template-dev, vsys: vsys1, status: unknown | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=1;;;0; 'panorama.template_assignments.total.count'=1;;;0; 'panorama.template_assignments.out_of_sync.count'=0;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    10
    ...    --exclude-template=dev --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    OK: Panorama total devices: 3, connected devices: 2, out of sync devices: 1, total device-groups: 0, total templates: 1, template assignments: 2, template assignments out of sync: 1, last push status: OK, last push age: 4029270 seconds - All devices are ok - All plugins are ok - template 'template-prod' template-devices-count : skipped (no value(s)) - All template assignments are synchronized | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=1;;;0; 'panorama.template_assignments.total.count'=2;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    11
    ...    --unknown-device-connection-status='\\\%{connected} eq "yes"' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    UNKNOWN: device 'fw-london.example.com' (FW-LONDON) connected: yes - device 'fw-nyc.example.com' (FW-NYC) connected: yes | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    12
    ...    --warning-device-connection-status='\\\%{connected} eq "yes"' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    WARNING: device 'fw-london.example.com' (FW-LONDON) connected: yes - device 'fw-nyc.example.com' (FW-NYC) connected: yes | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    13
    ...    --critical-device-connection-status='\\\%{connected} eq "yes"' --critical-plugin-status= --critical-template-sync-status=
    ...    CRITICAL: device 'fw-london.example.com' (FW-LONDON) connected: yes - device 'fw-nyc.example.com' (FW-NYC) connected: yes | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    14
    ...    --unknown-device-software-version='\\\%{sw_version} =~ /1/' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    UNKNOWN: device 'fw-london.example.com' (FW-LONDON) software version: 10.0.5 - device 'fw-nyc.example.com' (FW-NYC) software version: 10.1.3 - device 'fw-tokyo.example.com' (FW-TOKYO) software version: 10.1.1 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    15
    ...    --warning-device-software-version='\\\%{sw_version} =~ /1/' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    WARNING: device 'fw-london.example.com' (FW-LONDON) software version: 10.0.5 - device 'fw-nyc.example.com' (FW-NYC) software version: 10.1.3 - device 'fw-tokyo.example.com' (FW-TOKYO) software version: 10.1.1 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    16
    ...    --critical-device-software-version='\\\%{sw_version} =~ /1/' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    CRITICAL: device 'fw-london.example.com' (FW-LONDON) software version: 10.0.5 - device 'fw-nyc.example.com' (FW-NYC) software version: 10.1.3 - device 'fw-tokyo.example.com' (FW-TOKYO) software version: 10.1.1 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    17
    ...    --unknown-device-ha-state='\\\%{ha_state} =~ /passive/' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    UNKNOWN: device 'fw-london.example.com' (FW-LONDON) HA state: passive | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    18
    ...    --warning-device-ha-state='\\\%{ha_state} =~ /passive/' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    WARNING: device 'fw-london.example.com' (FW-LONDON) HA state: passive | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    19
    ...    --critical-device-ha-state='\\\%{ha_state} =~ /passive/' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    CRITICAL: device 'fw-london.example.com' (FW-LONDON) HA state: passive | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    20
    ...    --unknown-plugin-status='\\\%{status} =~ /failed/' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    UNKNOWN: plugin 'vmware' status: failed (version: 1.5.2) | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    21
    ...    --warning-plugin-status='\\\%{status} =~ /failed/' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    WARNING: plugin 'vmware' status: failed (version: 1.5.2) | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    22
    ...    --critical-plugin-status='\\\%{status} !~ /failed/' --critical-device-connection-status= --critical-template-sync-status=
    ...    CRITICAL: plugin 'cisco' status: success (version: 2.1.0) - plugin 'nutanix' status: success (version: 1.0.3) | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    23
    ...    --unknown-push-status='\\\%{push_status} =~ /OK/' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    UNKNOWN: Panorama last push status: OK | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    24
    ...    --warning-push-status='\\\%{push_status} =~ /OK/' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    WARNING: Panorama last push status: OK | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    25
    ...    --critical-push-status='\\\%{push_status} =~ /OK/' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    CRITICAL: Panorama last push status: OK | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    26
    ...    --warning-push-age=:1 --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    WARNING: Panorama last push age: 4029270 seconds | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;0:1;;0;
    ...    27
    ...    --critical-push-age=:1 --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    CRITICAL: Panorama last push age: 4029270 seconds | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;0:1;0;
    ...    28
    ...    --unknown-template-sync-status='\\\%{sync_status} =~ /out of sync/i' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    UNKNOWN: template-assignment 'FW-LONDON' template: template-prod, vsys: vsys1, status: out of sync | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    29
    ...    --warning-template-sync-status='\\\%{sync_status} =~ /out of sync/i' --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    WARNING: template-assignment 'FW-LONDON' template: template-prod, vsys: vsys1, status: out of sync | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    30
    ...    --critical-template-sync-status='\\\%{sync_status} =~ /out of sync/i' --critical-device-connection-status= --critical-plugin-status=
    ...    CRITICAL: template-assignment 'FW-LONDON' template: template-prod, vsys: vsys1, status: out of sync | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    31
    ...    --warning-devices-total=:1 --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    WARNING: Panorama total devices: 3 | 'panorama.devices.total.count'=3;0:1;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    32
    ...    --critical-devices-total=:1 --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    CRITICAL: Panorama total devices: 3 | 'panorama.devices.total.count'=3;;0:1;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    33
    ...    --warning-devices-connected=1 --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    WARNING: Panorama connected devices: 2 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;0:1;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    34
    ...    --critical-devices-connected=1 --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    CRITICAL: Panorama connected devices: 2 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;0:1;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    35
    ...    --warning-devices-out-of-sync=3: --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    WARNING: Panorama out of sync devices: 1 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;3:;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    36
    ...    --critical-devices-out-of-sync=3: --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    CRITICAL: Panorama out of sync devices: 1 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;3:;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    37
    ...    --warning-templates-total=:1 --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    WARNING: Panorama total templates: 2 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;0:1;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    38
    ...    --critical-templates-total=:1 --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    CRITICAL: Panorama total templates: 2 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;0:1;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    39
    ...    --warning-template-assignments-total=0 --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    WARNING: Panorama template assignments: 3 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;0:0;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    40
    ...    --critical-template-assignments-total=0 --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    CRITICAL: Panorama template assignments: 3 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;0:0;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    41
    ...    --warning-template-assignments-out-of-sync=0 --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    WARNING: Panorama template assignments out of sync: 1 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;0:0;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    42
    ...    --critical-template-assignments-out-of-sync=0 --critical-device-connection-status= --critical-plugin-status= --critical-template-sync-status=
    ...    CRITICAL: Panorama template assignments out of sync: 1 | 'panorama.devices.total.count'=3;;;0; 'panorama.devices.connected.count'=2;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;0:0;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    43
    ...    --include-device-serial=LONDO
    ...    CRITICAL: plugin 'vmware' status: failed (version: 1.5.2) - template-assignment 'FW-TOKYO' template: template-dev, vsys: unknown, status: disconnected - template-assignment 'FW-LONDON' template: template-prod, vsys: vsys1, status: out of sync - template-assignment 'FW-NYC' template: template-prod, vsys: unknown, status: disconnected | 'panorama.devices.total.count'=1;;;0; 'panorama.devices.connected.count'=1;;;0; 'panorama.devices.out_of_sync.count'=1;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=3;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
    ...    44
    ...    --exclude-device-serial=LONDO
    ...    CRITICAL: device 'fw-tokyo.example.com' (FW-TOKYO) connected: no - plugin 'vmware' status: failed (version: 1.5.2) - template-assignment 'FW-TOKYO' template: template-dev, vsys: vsys1, status: unknown - template-assignment 'FW-LONDON' template: template-prod, vsys: unknown, status: disconnected | 'panorama.devices.total.count'=2;;;0; 'panorama.devices.connected.count'=1;;;0; 'panorama.devices.out_of_sync.count'=0;;;0; 'panorama.device_groups.total.count'=0;;;0; 'panorama.templates.total.count'=2;;;0; 'panorama.template_assignments.total.count'=3;;;0; 'panorama.template_assignments.out_of_sync.count'=1;;;0; 'panorama.push.age.seconds'=4029270s;;;0;
