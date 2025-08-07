*** Settings ***
Documentation       Azure Network VPN Gateway plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}vpngatewaystatus.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${LOGIN_ENDPOINT}       ${BASE_URL}/login
${CMD}                  ${CENTREON_PLUGINS} --plugin=cloud::azure::network::vpngateway::plugin --custommode=api --subscription=subscription --tenant=tenant --client-id=client_id --client-secret=secret --resource-group=resource-group --login-endpoint=${LOGIN_ENDPOINT}


*** Test Cases ***
VPN Gateway status ${tc}
    [Tags]    cloud    azure    api    mockoon
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=vpn-gateway-status
    ...    --management-endpoint=${BASE_URL}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:         tc  extra_options                                                                            expected_result    --
            ...       1   ${EMPTY}                                                                                 OK: All VPN gateways are ok
            ...       2   --warning-status='\\%\{provisioning_state\} eq "Succeeded"'                              WARNING: VPN Gateway 'gateway1' Provisioning State 'Succeeded' [Gateway type: ExpressRoute] [VPN type: RouteBased] - VPN Gateway 'gateway2' Provisioning State 'Succeeded' [Gateway type: ExpressRoute] [VPN type: RouteBased]
            ...       3   --critical-status='\\%\{provisioning_state\} eq "Succeeded"'                             CRITICAL: VPN Gateway 'gateway1' Provisioning State 'Succeeded' [Gateway type: ExpressRoute] [VPN type: RouteBased] - VPN Gateway 'gateway2' Provisioning State 'Succeeded' [Gateway type: ExpressRoute] [VPN type: RouteBased]
            ...       4   --filter-name='gateway1'                                                                 OK: VPN Gateway 'gateway1' Provisioning State 'Succeeded' [Gateway type: ExpressRoute] [VPN type: RouteBased]
            ...       5   --filter-name='gateway1' --warning-status='\\%\{provisioning_state\} eq "Succeeded"'     WARNING: VPN Gateway 'gateway1' Provisioning State 'Succeeded' [Gateway type: ExpressRoute] [VPN type: RouteBased]
            ...       6   --filter-name='gateway1' --critical-status='\\%\{provisioning_state\} eq "Succeeded"'    CRITICAL: VPN Gateway 'gateway1' Provisioning State 'Succeeded' [Gateway type: ExpressRoute] [VPN type: RouteBased]

                                                     