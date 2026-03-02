*** Settings ***
Documentation       Cato Networks API Mode Events

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}cato-api.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=network::security::cato::networks::api::plugin
...                 --mode events
...                 --hostname=${HOSTNAME}
...                 --account-id=123
...                 --api-key=321
...                 --proto=http
...                 --port=${APIPORT}


*** Test Cases ***
Events ${tc}
    [Tags]    network    securirt    api    graphql    cato
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_string}

    Examples:      tc    extraoptions                                        expected_string    --
          ...      1     ${EMPTY}                                            OK: Number of records: 2 - All records are ok | 'count'=2;;;0;
          ...      2     --exclude-status                                    OK: Number of records: 3 - All records are ok | 'count'=3;;;0;
          ...      3     --include-status=Reopened                           OK: Number of records: 1 - Record 987659: event_id="987659", time_str="2025-09-18 09:25:44", event_type="Security", event_sub_type="Threat Prevention", severity="HIGH", title="Malware blocked", event_message="Suspicious file transfer blocked by IPS", pop_name="Frankfurt POP", src_site_name="Branch-2", dest_site_name="Internet" | 'count'=1;;;0;
          ...      4     --exclude='\\\%{pop_name} =~ /Paris/'               OK: Number of records: 1 - Record 987659: event_id="987659", time_str="2025-09-18 09:25:44", event_type="Security", event_sub_type="Threat Prevention", severity="HIGH", title="Malware blocked", event_message="Suspicious file transfer blocked by IPS", pop_name="Frankfurt POP", src_site_name="Branch-2", dest_site_name="Internet" | 'count'=1;;;0;
          ...      5     --exclude='\\\%{pop_name} =~ /Frankfurt/'           OK: Number of records: 1 - Record 123456: event_id="123456", time_str="2025-09-17 09:10:12", event_type="Sockets Management", event_sub_type="Socket Firmware Upgrade", severity="INFO", title="Socket upgraded successfully", event_message="Socket upgraded from version 4.0.3 to 4.0.4", pop_name="Paris POP", src_site_name="Headquarters", dest_site_name="Branch-1" | 'count'=1;;;0;
          ...      6     --critical-count=':1'                               CRITICAL: Number of records: 2 | 'count'=2;;0:1;0;
          ...      7     --warning-count=':1'                                WARNING: Number of records: 2 | 'count'=2;0:1;;0;
          ...      8     --warning-event='\\\%{event_type} =~ /Security/'    WARNING: Record 987659: event_id="987659", time_str="2025-09-18 09:25:44", event_type="Security", event_sub_type="Threat Prevention", severity="HIGH", title="Malware blocked", event_message="Suspicious file transfer blocked by IPS", pop_name="Frankfurt POP", src_site_name="Branch-2", dest_site_name="Internet" | 'count'=2;;;0;
          ...      9     --critical-event='\\\%{title} =~ /Malware/'         CRITICAL: Record 987659: event_id="987659", time_str="2025-09-18 09:25:44", event_type="Security", event_sub_type="Threat Prevention", severity="HIGH", title="Malware blocked", event_message="Suspicious file transfer blocked by IPS", pop_name="Frankfurt POP", src_site_name="Branch-2", dest_site_name="Internet" | 'count'=2;;;0;
