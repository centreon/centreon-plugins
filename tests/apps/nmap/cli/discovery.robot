*** Settings ***
Documentation       Check nmap discovery

Library             Collections
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${cmd}      ${CENTREON_PLUGINS}
...         --plugin=apps::nmap::cli::plugin
...         --mode=discovery


*** Test Cases ***
nmap ${tc}
    [Tags]    apps    nmap
    ${command}    Catenate
    ...    ${cmd}
    ...    --subnet='127.0.0.1/32'
    ...    --command-path=${CURDIR}${/}bin
    ...    --command=nmap${tc}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Json    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extraoptions
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    {"discovered_items":1,"end_time":1779205487,"results":[{"os":null,"vendor":null,"hostnames":[{"type":"PTR","name":"localhost"}],"type":"unknown","services":[{"port":"161/udp","name":"snmp"}],"status":"up","hostname":"localhost","addresses":[{"type":"ipv4","address":"127.0.0.1"}],"os_accuracy":null,"ip":"127.0.0.1"}],"duration":0,"start_time":1779205487}
    ...    2
    ...    --nmap-options='-sS -sU -R -O --osscan-limit --osscan-guess -p U:161,162,T:21-25,80,139,443,3306,5985,5986,8080,8443 -oX - '
    ...    {"end_time":1779205703,"discovered_items":1,"start_time":1779205703,"results":[{"ip":"127.0.0.1","type":"unknown","hostnames":[{"type":"PTR","name":"localhost"}],"hostname":"localhost","addresses":[{"address":"127.0.0.1","type":"ipv4"}],"os":null,"services":[{"port":"161/udp","name":"snmp"}],"vendor":null,"status":"up","os_accuracy":null}],"duration":0}
    ...    3
    ...    --nmap-options='-sS -oX - '
    ...    {"start_time":1779205487,"results":[{"type":"unknown","services":[{"name":"snmp","port":"161/udp"}],"hostnames":[{"type":"PTR","name":"localhost"}],"vendor":null,"os":null,"hostname":"localhost","addresses":[{"type":"ipv4","address":"127.0.0.1"}],"ip":"127.0.0.1","os_accuracy":null,"status":"up"}],"end_time":1779205488,"discovered_items":1,"duration":1}
