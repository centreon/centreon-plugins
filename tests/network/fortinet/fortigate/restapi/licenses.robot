*** Settings ***
Documentation       Check licenses.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}License-api.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=network::fortinet::fortigate::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --access-token=mokoon-token
...                 --port=${APIPORT}


*** Test Cases ***
licenses ${tc}
    [Tags]    network    fortinet    fortigate    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=licenses
    ...    ${extra_options}
    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:         tc      extra_options                                                                                                     expected_result    --
            ...       1       --warning-status='\\\%{name} eq /web_filtering/i'                                                                 CRITICAL: License 'ai_malware_detection' status: expired - License 'antispam' status: expired - License 'antivirus' status: expired - License 'blacklisted_certificates' status: expired - License 'botnet_domain' status: expired - License 'ips' status: expired - License 'malicious_urls' status: expired - License 'mobile_malware' status: expired - License 'web_filtering' status: expired | 'ai_malware_detection#license.expires.seconds'=0s;;;0; 'antispam#license.expires.seconds'=0s;;;0; 'antivirus#license.expires.seconds'=0s;;;0; 'appctrl#license.expires.seconds'=0s;;;0; 'blacklisted_certificates#license.expires.seconds'=0s;;;0; 'botnet_domain#license.expires.seconds'=0s;;;0; 'device_os_id#license.expires.seconds'=0s;;;0; 'forticare:support:enhanced#license.expires.seconds'=0s;;;0; 'forticare:support:hardware#license.expires.seconds'=0s;;;0; 'forticloud_sandbox#license.expires.seconds'=0s;;;0; 'fortiems_cloud#license.expires.seconds'=0s;;;0; 'ips#license.expires.seconds'=0s;;;0;
            ...       2       --critical-status='\\\%{status} =~ /unavailable/i'                                                                CRITICAL: License 'sms' status: unavailable | 'ai_malware_detection#license.expires.seconds'=0s;;;0; 'antispam#license.expires.seconds'=0s;;;0; 'antivirus#license.expires.seconds'=0s;;;0; 'appctrl#license.expires.seconds'=0s;;;0; 'blacklisted_certificates#license.expires.seconds'=0s;;;0; 'botnet_domain#license.expires.seconds'=0s;;;0; 'device_os_id#license.expires.seconds'=0s;;;0; 'forticare:support:enhanced#license.expires.seconds'=0s;;;0; 'forticare:support:hardware#license.expires.seconds'=0s;;;0; 'forticloud_sandbox#license.expires.seconds'=0s;;;0; 'fortiems_cloud#license.expires.seconds'=0s;;;0; 'ips#license.expires.seconds'=0s;;;0; 'malicious_urls#license.expires.seconds'=0s;;;0; 'mobile_malware#license.expires.seconds'=0s;;;0; 'web_filtering#license.expires.seconds'=0s;;;0;
            ...       3       --filter-name='sms'                                                                                               OK: License 'sms' status: unavailable
            ...       4       --unit='w'                                                                                                        CRITICAL: License 'ai_malware_detection' status: expired - License 'antispam' status: expired - License 'antivirus' status: expired - License 'blacklisted_certificates' status: expired - License 'botnet_domain' status: expired - License 'ips' status: expired - License 'malicious_urls' status: expired - License 'mobile_malware' status: expired - License 'web_filtering' status: expired | 'ai_malware_detection#license.expires.weeks'=0w;;;0; 'antispam#license.expires.weeks'=0w;;;0; 'antivirus#license.expires.weeks'=0w;;;0; 'appctrl#license.expires.weeks'=0w;;;0; 'blacklisted_certificates#license.expires.weeks'=0w;;;0; 'botnet_domain#license.expires.weeks'=0w;;;0; 'device_os_id#license.expires.weeks'=0w;;;0; 'forticare:support:enhanced#license.expires.weeks'=0w;;;0; 'forticare:support:hardware#license.expires.weeks'=0w;;;0; 'forticloud_sandbox#license.expires.weeks'=0w;;;0; 'fortiems_cloud#license.expires.weeks'=0w;;;0; 'ips#license.expires.weeks'=0w;;;0; 'malicious_urls#license.expires.weeks'=0w;;;0; 'mobile_malware#license.expires.weeks'=0w;;;0; 'web_filtering#license.expires.weeks'=0w;;;0;
            ...       5       --critical-status='' --warning-expires=0 --critical-expires=20                                                    OK: All licenses are ok | 'ai_malware_detection#license.expires.seconds'=0s;0:0;0:20;0; 'antispam#license.expires.seconds'=0s;0:0;0:20;0; 'antivirus#license.expires.seconds'=0s;0:0;0:20;0; 'appctrl#license.expires.seconds'=0s;0:0;0:20;0; 'blacklisted_certificates#license.expires.seconds'=0s;0:0;0:20;0; 'botnet_domain#license.expires.seconds'=0s;0:0;0:20;0; 'device_os_id#license.expires.seconds'=0s;0:0;0:20;0; 'forticare:support:enhanced#license.expires.seconds'=0s;0:0;0:20;0; 'forticare:support:hardware#license.expires.seconds'=0s;0:0;0:20;0; 'forticloud_sandbox#license.expires.seconds'=0s;0:0;0:20;0; 'fortiems_cloud#license.expires.seconds'=0s;0:0;0:20;0; 'ips#license.expires.seconds'=0s;0:0;0:20;0; 'malicious_urls#license.expires.seconds'=0s;0:0;0:20;0; 'mobile_malware#license.expires.seconds'=0s;0:0;0:20;0; 'web_filtering#license.expires.seconds'=0s;0:0;0:20;0;
            ...       6       --warning-status='' --warning-last-update=0 --critical-last-update=100 --filter-name='forticloud_sandbox'         OK: License 'forticloud_sandbox' status: free_license, expires in 0 | 'forticloud_sandbox#license.expires.seconds'=0s;;;0;
