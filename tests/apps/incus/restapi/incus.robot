*** Settings ***
Documentation       Incus REST API modes.
...                 Copy this directory to centreon-plugins/tests/apps/incus/restapi/
...                 before running it. The resource path is three directories up
...                 from that location. snmpsim does not apply: this plugin talks
...                 to the Incus HTTPS API, simulated here with Mockoon.
...                 The suite creates a client certificate and a state directory,
...                 then deletes them. Nothing secret is stored in the repository.
...                 Instance usage runs three checks in order. The second check
...                 reads the statefile written by the first, and the third applies
...                 --warning-cpu to that same sample. Ages use a digit pattern
...                 because a 2021 timestamp changes at every run.
...                 Bodies come from t/fixtures. cluster-disabled.json and
...                 forbidden.json are not served by the default environment.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Incus Api
Suite Teardown      Stop Incus Api
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}incus.mockoon.json
${CERT}             ${TEMPDIR}${/}incus-client.pem
${KEY}              ${TEMPDIR}${/}incus-client.key
${STATE}            ${TEMPDIR}${/}incus-state

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::incus::restapi::plugin
...                 --custommode=api
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --timeout=5
...                 --cert-file=${CERT}
...                 --key-file=${KEY}

${INSTANCES}    ^CRITICAL:\\ instance\\ 'backup0'\\ status\\ Error\\ \\-\\ instance\\ 'snap0'\\ status\\ Frozen\\ \\|\\ 'incus\\.instances\\.running\\.count'=1;;;0;\\ 'incus\\.instances\\.stopped\\.count'=1;;;0;\\ 'incus\\.instances\\.frozen\\.count'=1;;;0;\\ 'incus\\.instances\\.error\\.count'=1;;;0;$
${INSTANCES_RUNNING_WARNING}    ^CRITICAL:\\ instance\\ 'backup0'\\ status\\ Error\\ \\-\\ instance\\ 'snap0'\\ status\\ Frozen\\ WARNING:\\ instances\\ running:\\ 1\\ \\|\\ 'incus\\.instances\\.running\\.count'=1;0:0;;0;\\ 'incus\\.instances\\.stopped\\.count'=1;;;0;\\ 'incus\\.instances\\.frozen\\.count'=1;;;0;\\ 'incus\\.instances\\.error\\.count'=1;;;0;$
${USAGE_FIRST}    ^OK:\\ instances\\ running:\\ 2\\ \\-\\ all\\ instance\\ usage\\ are\\ ok\\ \\-\\ disk\\ 'foo/root'\\ disk\\ used:\\ 478\\.97\\ MB,\\ disk:\\ 100\\.00\\ %\\ \\-\\ network\\ 'foo/vethbbcd39c7'\\s+\\|\\ 'incus\\.instances\\.running\\.count'=2;;;0;\\ 'backup0\\#incus\\.instance\\.memory\\.usage\\.bytes'=73248768B;;;0;\\ 'foo\\#incus\\.instance\\.memory\\.usage\\.bytes'=73248768B;;;0;\\ 'foo\\#incus\\.instance\\.memory\\.usage\\.percentage'=595\\.64%;;;0;\\ 'foo/root\\#incus\\.instance\\.disk\\.usage\\.bytes'=502239232B;;;0;\\ 'foo/root\\#incus\\.instance\\.disk\\.usage\\.percentage'=100\\.00%;;;0;$
${USAGE_SECOND}    ^OK:\\ instances\\ running:\\ 2\\ \\-\\ all\\ instance\\ usage\\ are\\ ok\\ \\-\\ disk\\ 'foo/root'\\ disk\\ used:\\ 478\\.97\\ MB,\\ disk:\\ 100\\.00\\ %\\ \\-\\ network\\ 'foo/vethbbcd39c7'\\ traffic\\ in:\\ 0\\.00\\ b/s,\\ traffic\\ out:\\ 0\\.00\\ b/s\\ \\|\\ 'incus\\.instances\\.running\\.count'=2;;;0;\\ 'backup0\\#incus\\.instance\\.memory\\.usage\\.bytes'=73248768B;;;0;\\ 'foo\\#incus\\.instance\\.cpu\\.utilization\\.percentage'=0\\.00%;;;0;\\ 'foo\\#incus\\.instance\\.memory\\.usage\\.bytes'=73248768B;;;0;\\ 'foo\\#incus\\.instance\\.memory\\.usage\\.percentage'=595\\.64%;;;0;\\ 'foo/root\\#incus\\.instance\\.disk\\.usage\\.bytes'=502239232B;;;0;\\ 'foo/root\\#incus\\.instance\\.disk\\.usage\\.percentage'=100\\.00%;;;0;\\ 'foo/vethbbcd39c7\\#incus\\.instance\\.network\\.in\\.bytespersecond'=0\\.00B/s;;;0;\\ 'foo/vethbbcd39c7\\#incus\\.instance\\.network\\.out\\.bytespersecond'=0\\.00B/s;;;0;$
${USAGE_CPU_WARNING}    ^WARNING:\\ instance\\ 'foo'\\ cpu:\\ 0\\.00\\ %\\ \\|\\ 'incus\\.instances\\.running\\.count'=2;;;0;\\ 'backup0\\#incus\\.instance\\.memory\\.usage\\.bytes'=73248768B;;;0;\\ 'foo\\#incus\\.instance\\.cpu\\.utilization\\.percentage'=0\\.00%;1:;;0;\\ 'foo\\#incus\\.instance\\.memory\\.usage\\.bytes'=73248768B;;;0;\\ 'foo\\#incus\\.instance\\.memory\\.usage\\.percentage'=595\\.64%;;;0;\\ 'foo/root\\#incus\\.instance\\.disk\\.usage\\.bytes'=502239232B;;;0;\\ 'foo/root\\#incus\\.instance\\.disk\\.usage\\.percentage'=100\\.00%;;;0;\\ 'foo/vethbbcd39c7\\#incus\\.instance\\.network\\.in\\.bytespersecond'=0\\.00B/s;;;0;\\ 'foo/vethbbcd39c7\\#incus\\.instance\\.network\\.out\\.bytespersecond'=0\\.00B/s;;;0;$
${STORAGE}    ^OK:\\ storage\\ pools:\\ 1\\ \\-\\ pool\\ 'local'\\ space\\ used:\\ 319\\.94\\ GB,\\ space:\\ 81\\.77\\ %,\\ inodes\\ used:\\ 23937695,\\ inodes:\\ 0\\.08\\ %\\ \\|\\ 'incus\\.storage\\.pools\\.count'=1;;;0;\\ 'local\\#incus\\.storage\\.space\\.usage\\.bytes'=343537419776B;;;0;\\ 'local\\#incus\\.storage\\.space\\.usage\\.percentage'=81\\.77%;;;0;\\ 'local\\#incus\\.storage\\.inodes\\.usage\\.count'=23937695;;;0;\\ 'local\\#incus\\.storage\\.inodes\\.usage\\.percentage'=0\\.08%;;;0;$
${WARNINGS}    ^CRITICAL:\\ warnings\\ new:\\ 1\\ \\-\\ \\[low\\]\\ Couldn't\\ find\\ CGroup\\ on\\ instances/c1\\ \\(x1,\\ last\\ 2021\\-03\\-23T17:38\\):\\ Couldn't\\ find\\ the\\ CGroup\\ blkio\\.weight,\\ disk\\ priority\\ will\\ be\\ ignored\\ \\|\\ 'incus\\.warnings\\.new\\.count'=1;;\\~:0;0;$
${NETWORKS}    ^OK:\\ networks\\ networks:\\ 2,\\ used\\ by:\\ 2,\\ ok\\ \\|\\ 'incus\\.networks\\.count'=2;;;0;\\ 'incus\\.networks\\.used_by\\.count'=2;;;0;$
${CLUSTER}    ^OK:\\ cluster\\ offline:\\ 0,\\ all\\ cluster\\ members\\ are\\ Online\\ \\|\\ 'incus\\.cluster\\.members\\.offline\\.count'=0;;;0;$
${SNAPSHOTS}    ^OK:\\ all\\ instance\\ snapshots\\ are\\ ok\\ \\|\\ 'backup0\\#incus\\.snapshots\\.count'=0;;;0;\\ 'c1\\#incus\\.snapshots\\.count'=0;;;0;\\ 'foo\\#incus\\.snapshots\\.count'=2;;;0;\\ 'foo\\#incus\\.snapshots\\.newest\\.age\\.seconds'=\\d+s;;;0;$
${OPERATIONS}    ^OK:\\ operations\\ running:\\ 2,\\ oldest\\ age:\\ \\d+\\ s\\ \\|\\ 'incus\\.operations\\.running\\.count'=2;;;0;\\ 'incus\\.operations\\.oldest\\.age\\.seconds'=\\d+s;;;0;$


*** Keywords ***
Start Incus Api
    Run Keyword And Ignore Error    Remove Directory    ${STATE}    recursive=True
    Create Directory    ${STATE}
    ${result}    Run Process
    ...    openssl
    ...    req
    ...    -x509
    ...    -newkey
    ...    rsa:2048
    ...    -nodes
    ...    -days
    ...    1
    ...    -subj
    ...    /CN\=incus-robot
    ...    -keyout
    ...    ${KEY}
    ...    -out
    ...    ${CERT}
    ...    stderr=STDOUT
    Should Be Equal As Integers    ${result.rc}    0    ${result.stdout}
    Start Mockoon    ${MOCKOON_JSON}

Stop Incus Api
    Stop Mockoon
    Remove File    ${CERT}
    Remove File    ${KEY}
    Remove Directory    ${STATE}    recursive=True


*** Test Cases ***
Instances
    [Documentation]    Status from recursion 1, then the running-count threshold.
    [Tags]    apps    incus    restapi
    ${command}    Catenate    ${CMD}    --mode\=instances
    Ctn Run Command And Check Result As Regexp    ${command}    ${INSTANCES}
    ${warned}    Catenate    ${command}    --warning-running\=0
    Ctn Run Command And Check Result As Regexp    ${warned}    ${INSTANCES_RUNNING_WARNING}

Instance usage
    [Documentation]    First sample skips CPU and network rates. Second sample
    ...    rates are zero because the counters did not move. Third sample
    ...    warns because 0.00 % is outside --warning-cpu=1:.
    [Tags]    apps    incus    restapi
    ${command}    Catenate    ${CMD}    --mode\=instance-usage    --statefile-dir\=${STATE}
    Ctn Run Command And Check Result As Regexp    ${command}    ${USAGE_FIRST}
    Ctn Run Command And Check Result As Regexp    ${command}    ${USAGE_SECOND}
    ${warned}    Catenate    ${command}    --warning-cpu\=1:
    Ctn Run Command And Check Result As Regexp    ${warned}    ${USAGE_CPU_WARNING}

Storage
    [Tags]    apps    incus    restapi
    ${command}    Catenate    ${CMD}    --mode\=storage
    Ctn Run Command And Check Result As Regexp    ${command}    ${STORAGE}

Warnings
    [Tags]    apps    incus    restapi
    ${command}    Catenate    ${CMD}    --mode\=warnings
    Ctn Run Command And Check Result As Regexp    ${command}    ${WARNINGS}

Networks
    [Tags]    apps    incus    restapi
    ${command}    Catenate    ${CMD}    --mode\=networks
    Ctn Run Command And Check Result As Regexp    ${command}    ${NETWORKS}

Cluster
    [Tags]    apps    incus    restapi
    ${command}    Catenate    ${CMD}    --mode\=cluster
    Ctn Run Command And Check Result As Regexp    ${command}    ${CLUSTER}

Snapshots
    [Tags]    apps    incus    restapi
    ${command}    Catenate    ${CMD}    --mode\=snapshots
    Ctn Run Command And Check Result As Regexp    ${command}    ${SNAPSHOTS}

Operations
    [Tags]    apps    incus    restapi
    ${command}    Catenate    ${CMD}    --mode\=operations
    Ctn Run Command And Check Result As Regexp    ${command}    ${OPERATIONS}

Transport guards
    [Documentation]    No request is sent. The core message names cert-file,
    ...    whether it comes from the validator or from the manual check.
    [Tags]    apps    incus    restapi
    ${missing}    Catenate
    ...    ${CENTREON_PLUGINS}
    ...    --plugin\=apps::incus::restapi::plugin
    ...    --mode\=instances
    ...    --hostname\=${HOSTNAME}
    ...    --port\=${APIPORT}
    ...    --proto\=http
    Ctn Run Command And Check Result As Regexp    ${missing}    ^UNKNOWN:.*cert-file
    ${insecure}    Catenate    ${CMD}    --mode\=instances    --insecure
    Ctn Run Command And Check Result As Regexp    ${insecure}    ^UNKNOWN: Refusing --insecure
