*** Settings ***
Documentation       cloud::zscaler::ztb::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::zscaler::ztb::restapi::plugin
...                 --mode=discovery
...                 --login-domain=127.0.0.1
...                 --api-domain=127.0.0.1
...                 --client-id=client-id
...                 --client-secret=client-secret
...                 --port=${APIPORT}
...                 --proto=http
...                 --timeout=10


*** Test Cases ***
Discovery ${tc}
    [Tags]    cloud    zscaler    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Json    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    {"discovered_items":10,"results":[{"cluster_id":233,"cluster_name":"LOCATION_1-cluster","gw_desired_state":"standby","gw_display_name":"LOCATION_102","gw_health_color":"green","gw_id":"id1","gw_ip_address":"192.0.2.81","gw_last_poll_update":"2026-07-10T08:51:41Z","gw_name":"LOCATION_101","gw_operational_state":"standby","gw_running_version":"8.0.8P2","gw_vrrp_state":"backup","site_id":"fake-id","site_name":"LOCATION_1","uuid":"id1"},{"cluster_id":233,"cluster_name":"LOCATION_1-cluster","gw_desired_state":"active","gw_display_name":"LOCATION_101","gw_health_color":"green","gw_id":"id1","gw_ip_address":"192.0.2.82","gw_last_poll_update":"2026-07-10T08:51:43Z","gw_name":"LOCATION_102","gw_operational_state":"active","gw_running_version":"8.0.8P2","gw_vrrp_state":"master","site_id":"fake-id","site_name":"LOCATION_1","uuid":"id1"},{"cluster_id":213,"cluster_name":"LOCATION_2-1-cluster","gw_desired_state":"standby","gw_display_name":"LOCATION_201","gw_health_color":"green","gw_id":"id3","gw_ip_address":"192.0.2.65","gw_last_poll_update":"2026-07-10T08:51:50Z","gw_name":"LOCATION_2-1-gw-01","gw_operational_state":"standby","gw_running_version":"8.0.8P3a","gw_vrrp_state":"backup","site_id":"fake-id","site_name":"LOCATION_2-1","uuid":"id3"},{"cluster_id":213,"cluster_name":"LOCATION_2-1-cluster","gw_desired_state":"active","gw_display_name":"LOCATION_202","gw_health_color":"green","gw_id":"id3","gw_ip_address":"192.0.2.66","gw_last_poll_update":"2026-07-10T08:51:48Z","gw_name":"LOCATION_2-1-gw-02","gw_operational_state":"active","gw_running_version":"8.0.8P3a","gw_vrrp_state":"master","site_id":"fake-id","site_name":"LOCATION_2-1","uuid":"id3"},{"cluster_id":292,"cluster_name":"LOCATION_3-cluster","gw_desired_state":"standby","gw_display_name":"LOCATION_301","gw_health_color":"green","gw_id":"id4","gw_ip_address":"192.0.2.33","gw_last_poll_update":"2026-07-10T08:51:50Z","gw_name":"LOCATION_301","gw_operational_state":"standby","gw_running_version":"8.0.8P3a","gw_vrrp_state":"backup","site_id":"fake-id","site_name":"LOCATION_3","uuid":"id4"},{"cluster_id":292,"cluster_name":"LOCATION_3-cluster","gw_desired_state":"active","gw_display_name":"LOCATION_302","gw_health_color":"green","gw_id":"id5","gw_ip_address":"192.0.2.34","gw_last_poll_update":"2026-07-10T08:51:50Z","gw_name":"LOCATION_302","gw_operational_state":"active","gw_running_version":"8.0.8P3a","gw_vrrp_state":"master","site_id":"fake-id","site_name":"LOCATION_3","uuid":"id5"},{"cluster_id":287,"cluster_name":"LOCATION_4-cluster","gw_desired_state":"standby","gw_display_name":"LOCATION_401","gw_health_color":"green","gw_id":"id6","gw_ip_address":"192.0.2.35","gw_last_poll_update":"2026-07-10T08:51:42Z","gw_name":"LOCATION_401","gw_operational_state":"standby","gw_running_version":"8.0.8P3a","gw_vrrp_state":"backup","site_id":"fake-id","site_name":"LOCATION_4","uuid":"id6"},{"cluster_id":287,"cluster_name":"LOCATION_4-cluster","gw_desired_state":"active","gw_display_name":"LOCATION_402","gw_health_color":"green","gw_id":"id7","gw_ip_address":"192.0.2.36","gw_last_poll_update":"2026-07-10T08:51:38Z","gw_name":"LOCATION_402","gw_operational_state":"active","gw_running_version":"8.0.8P3a","gw_vrrp_state":"master","site_id":"fake-id","site_name":"LOCATION_4","uuid":"id7"},{"cluster_id":291,"cluster_name":"LOCATION_5-cluster","gw_desired_state":"active","gw_display_name":"LOCATION_501","gw_health_color":"green","gw_id":"id8","gw_ip_address":"192.0.2.49","gw_last_poll_update":"2026-07-10T08:51:51Z","gw_name":"LOCATION_501","gw_operational_state":"active","gw_running_version":"8.0.8P3a","gw_vrrp_state":"master","site_id":"fake-id","site_name":"LOCATION_5","uuid":"id8"},{"cluster_id":291,"cluster_name":"LOCATION_5-cluster","gw_desired_state":"standby","gw_display_name":"LOCATION_502","gw_health_color":"green","gw_id":"id10","gw_ip_address":"192.0.2.50","gw_last_poll_update":"2026-07-10T08:51:42Z","gw_name":"LOCATION_502","gw_operational_state":"standby","gw_running_version":"8.0.8P3a","gw_vrrp_state":"backup","site_id":"fake-id","site_name":"LOCATION_5","uuid":"id10"}]}
    ...    2
    ...    --resource-type=gateway
    ...    {"discovered_items":10,"results":[{"cluster_id":233,"cluster_name":"LOCATION_1-cluster","gw_desired_state":"standby","gw_display_name":"LOCATION_102","gw_health_color":"green","gw_id":"id1","gw_ip_address":"192.0.2.81","gw_last_poll_update":"2026-07-10T08:51:41Z","gw_name":"LOCATION_101","gw_operational_state":"standby","gw_running_version":"8.0.8P2","gw_vrrp_state":"backup","site_id":"fake-id","site_name":"LOCATION_1","uuid":"id1"},{"cluster_id":233,"cluster_name":"LOCATION_1-cluster","gw_desired_state":"active","gw_display_name":"LOCATION_101","gw_health_color":"green","gw_id":"id1","gw_ip_address":"192.0.2.82","gw_last_poll_update":"2026-07-10T08:51:43Z","gw_name":"LOCATION_102","gw_operational_state":"active","gw_running_version":"8.0.8P2","gw_vrrp_state":"master","site_id":"fake-id","site_name":"LOCATION_1","uuid":"id1"},{"cluster_id":213,"cluster_name":"LOCATION_2-1-cluster","gw_desired_state":"standby","gw_display_name":"LOCATION_201","gw_health_color":"green","gw_id":"id3","gw_ip_address":"192.0.2.65","gw_last_poll_update":"2026-07-10T08:51:50Z","gw_name":"LOCATION_2-1-gw-01","gw_operational_state":"standby","gw_running_version":"8.0.8P3a","gw_vrrp_state":"backup","site_id":"fake-id","site_name":"LOCATION_2-1","uuid":"id3"},{"cluster_id":213,"cluster_name":"LOCATION_2-1-cluster","gw_desired_state":"active","gw_display_name":"LOCATION_202","gw_health_color":"green","gw_id":"id3","gw_ip_address":"192.0.2.66","gw_last_poll_update":"2026-07-10T08:51:48Z","gw_name":"LOCATION_2-1-gw-02","gw_operational_state":"active","gw_running_version":"8.0.8P3a","gw_vrrp_state":"master","site_id":"fake-id","site_name":"LOCATION_2-1","uuid":"id3"},{"cluster_id":292,"cluster_name":"LOCATION_3-cluster","gw_desired_state":"standby","gw_display_name":"LOCATION_301","gw_health_color":"green","gw_id":"id4","gw_ip_address":"192.0.2.33","gw_last_poll_update":"2026-07-10T08:51:50Z","gw_name":"LOCATION_301","gw_operational_state":"standby","gw_running_version":"8.0.8P3a","gw_vrrp_state":"backup","site_id":"fake-id","site_name":"LOCATION_3","uuid":"id4"},{"cluster_id":292,"cluster_name":"LOCATION_3-cluster","gw_desired_state":"active","gw_display_name":"LOCATION_302","gw_health_color":"green","gw_id":"id5","gw_ip_address":"192.0.2.34","gw_last_poll_update":"2026-07-10T08:51:50Z","gw_name":"LOCATION_302","gw_operational_state":"active","gw_running_version":"8.0.8P3a","gw_vrrp_state":"master","site_id":"fake-id","site_name":"LOCATION_3","uuid":"id5"},{"cluster_id":287,"cluster_name":"LOCATION_4-cluster","gw_desired_state":"standby","gw_display_name":"LOCATION_401","gw_health_color":"green","gw_id":"id6","gw_ip_address":"192.0.2.35","gw_last_poll_update":"2026-07-10T08:51:42Z","gw_name":"LOCATION_401","gw_operational_state":"standby","gw_running_version":"8.0.8P3a","gw_vrrp_state":"backup","site_id":"fake-id","site_name":"LOCATION_4","uuid":"id6"},{"cluster_id":287,"cluster_name":"LOCATION_4-cluster","gw_desired_state":"active","gw_display_name":"LOCATION_402","gw_health_color":"green","gw_id":"id7","gw_ip_address":"192.0.2.36","gw_last_poll_update":"2026-07-10T08:51:38Z","gw_name":"LOCATION_402","gw_operational_state":"active","gw_running_version":"8.0.8P3a","gw_vrrp_state":"master","site_id":"fake-id","site_name":"LOCATION_4","uuid":"id7"},{"cluster_id":291,"cluster_name":"LOCATION_5-cluster","gw_desired_state":"active","gw_display_name":"LOCATION_501","gw_health_color":"green","gw_id":"id8","gw_ip_address":"192.0.2.49","gw_last_poll_update":"2026-07-10T08:51:51Z","gw_name":"LOCATION_501","gw_operational_state":"active","gw_running_version":"8.0.8P3a","gw_vrrp_state":"master","site_id":"fake-id","site_name":"LOCATION_5","uuid":"id8"},{"cluster_id":291,"cluster_name":"LOCATION_5-cluster","gw_desired_state":"standby","gw_display_name":"LOCATION_502","gw_health_color":"green","gw_id":"id10","gw_ip_address":"192.0.2.50","gw_last_poll_update":"2026-07-10T08:51:42Z","gw_name":"LOCATION_502","gw_operational_state":"standby","gw_running_version":"8.0.8P3a","gw_vrrp_state":"backup","site_id":"fake-id","site_name":"LOCATION_5","uuid":"id10"}]}
    ...    3
    ...    --resource-type=site
    ...    {"discovered_items":2,"results":[{"id":"id1","name":"LOCATION_6","site_status":"active","uuid":"id1"},{"id":"id2","name":"LOCATION_7","site_status":"active","uuid":"id2"}]}
    ...    4
    ...    --resource-type=cluster
    ...    {"discovered_items":5,"results":[{"name":"LOCATION_1-cluster","uuid":"233"},{"name":"LOCATION_2-1-cluster","uuid":"213"},{"name":"LOCATION_3-cluster","uuid":"292"},{"name":"LOCATION_4-cluster","uuid":"287"},{"name":"LOCATION_5-cluster","uuid":"291"}]}
