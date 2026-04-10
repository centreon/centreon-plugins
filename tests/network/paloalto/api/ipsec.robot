*** Settings ***
Documentation       Check PaloAlto IPsec VPN tunnels status and lifetime.

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
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --mode=ipsec

*** Test Cases ***
paloalto-ipsec ${tc}
    [Tags]    network    paloalto    api    tunnel

    ${command}    Catenate
    ...    ${CMD}
    ...    --auth-type=api-key
    ...    --api-key=D@pAs$W@rD
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                         expected_result    --
            ...      1     ${EMPTY}                              OK: Tunnels count: 3 - All tunnels are ok | 'tunnels.count'=3;;;0; 'Nom du tunnel 1#tunnel.remain.seconds'=1727s;;;0; 'Nom du tunnel 2#tunnel.remain.seconds'=1727s;;;0; 'Nom du tunnel 3#tunnel.remain.seconds'=1727s;;;0;
            ...      2     --include-gateway-name='ateway 3'     OK: Tunnels count: 1 - tunnel 'Nom du tunnel 3' remain: 1727 seconds, encryption: G256, gateway: Nom de la Gateway 3 | 'tunnels.count'=1;;;0; 'Nom du tunnel 3#tunnel.remain.seconds'=1727s;;;0;
            ...      3     --exclude-gateway-name='ateway 1'     OK: Tunnels count: 2 - All tunnels are ok | 'tunnels.count'=2;;;0; 'Nom du tunnel 2#tunnel.remain.seconds'=1727s;;;0; 'Nom du tunnel 3#tunnel.remain.seconds'=1727s;;;0;
            ...      4     --include-tunnel-name='unnel 2'       OK: Tunnels count: 1 - tunnel 'Nom du tunnel 2' remain: 1727 seconds, encryption: G256, gateway: Nom de la Gateway 2 | 'tunnels.count'=1;;;0; 'Nom du tunnel 2#tunnel.remain.seconds'=1727s;;;0;
            ...      5     --exclude-tunnel-name='unnel 3'       OK: Tunnels count: 2 - All tunnels are ok | 'tunnels.count'=2;;;0; 'Nom du tunnel 1#tunnel.remain.seconds'=1727s;;;0; 'Nom du tunnel 2#tunnel.remain.seconds'=1727s;;;0;
            ...      6     --warning-tunnels-count=:1            WARNING: Tunnels count: 3 | 'tunnels.count'=3;0:1;;0; 'Nom du tunnel 1#tunnel.remain.seconds'=1727s;;;0; 'Nom du tunnel 2#tunnel.remain.seconds'=1727s;;;0; 'Nom du tunnel 3#tunnel.remain.seconds'=1727s;;;0;
            ...      7     --critical-tunnels-count=:1           CRITICAL: Tunnels count: 3 | 'tunnels.count'=3;;0:1;0; 'Nom du tunnel 1#tunnel.remain.seconds'=1727s;;;0; 'Nom du tunnel 2#tunnel.remain.seconds'=1727s;;;0; 'Nom du tunnel 3#tunnel.remain.seconds'=1727s;;;0;
            ...      8     --warning-remain-time=:1000           WARNING: tunnel 'Nom du tunnel 1' remain: 1727 seconds - tunnel 'Nom du tunnel 2' remain: 1727 seconds - tunnel 'Nom du tunnel 3' remain: 1727 seconds | 'tunnels.count'=3;;;0; 'Nom du tunnel 1#tunnel.remain.seconds'=1727s;0:1000;;0; 'Nom du tunnel 2#tunnel.remain.seconds'=1727s;0:1000;;0; 'Nom du tunnel 3#tunnel.remain.seconds'=1727s;0:1000;;0;
            ...      9     --critical-remain-time=:1000          CRITICAL: tunnel 'Nom du tunnel 1' remain: 1727 seconds - tunnel 'Nom du tunnel 2' remain: 1727 seconds - tunnel 'Nom du tunnel 3' remain: 1727 seconds | 'tunnels.count'=3;;;0; 'Nom du tunnel 1#tunnel.remain.seconds'=1727s;;0:1000;0; 'Nom du tunnel 2#tunnel.remain.seconds'=1727s;;0:1000;0; 'Nom du tunnel 3#tunnel.remain.seconds'=1727s;;0:1000;0;
