*** Settings ***
Documentation       Cloud Kubernetes REST API list-pods

Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}cloud-kubernetes-list-pods.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::kubernetes::plugin
...                 --mode list-pods
...                 --hostname=${HOSTNAME}
...                 --token=x-xxx
...                 --proto=http
...                 --port=${APIPORT}
...                 --custommode=api

*** Test Cases ***
List Pods ${tc}
    [Tags]    cloud     kubernetes

    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    extraoptions                                                    expected_result   --
        ...      1     ${EMPTY}                                                        ^List pods: \\\\n\\\\[.*ip = 192\\\\.168\\\\.1\\\\.210\\\\]\\\\n\\\\[.*ip = \\\\]\\\\Z
        ...      2     --disco-show --namespace='' --filter-name="test-1"              \\\\<\\\\?xml version="1.0" encoding="utf-8"\\\\?\\\\>\\\\n\\\\<data\\\\>(\\\\n\\\\s*\\\\<label .*ip="192.168.1.210".*\\\\/\\\\>){1}\\\\n\\\\<\\\\/data\\\\>

        ...      3     --disco-show --namespace='flux-test' --filter-name="test-2"     \\\\<\\\\?xml version="1.0" encoding="utf-8"\\\\?\\\\>\\\\n\\\\<data\\\\>(\\\\n\\\\s*\\\\<label .*ip="".*\\\\/\\\\>){1}\\\\n\\\\<\\\\/data\\\\>

