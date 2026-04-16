*** Settings ***
Documentation       OpenStack Load Balancer

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}openstack.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=cloud::openstack::restapi::plugin
...                 --mode=loadbalancer
...                 --identity-url=http://${HOSTNAME}:${APIPORT}/v3
...                 --username=xxx
...                 --password=P@s$WoRdZ


*** Test Cases ***
LoadBalancer ${tc}
    [Tags]    cloud     openstack     api
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings   ${command}    ${expected_string}

    Examples:        tc    extraoptions                                                                 expected_string    --
            ...      1     ${EMPTY}                                                                     OK: LoadBalancer count: 2 - All load balancers are ok | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
            ...      2     --disco-format                                                               <?xml version="1.0" encoding="utf-8"?> <data> <element>id</element> <element>name</element> <element>operating_status</element> <element>provisioning_status</element> <element>admin_state_up</element> <element>vip_address</element> <element>description</element> <element>provider</element> <element>pool_count</element> <element>listener_count</element> <element>project_id</element> </data>
            ...      3     --disco-show                                                                 <?xml version="1.0" encoding="utf-8"?> <data> <label admin_state_up="True" description="Load balancer for test 1" id="lb-001" listener_count="1" name="web-loadbalancer-01" operating_status="ONLINE" pool_count="1" project_id="project-001" provider="octavia" provisioning_status="ACTIVE" vip_address="192.168.10.10"/> <label admin_state_up="True" description="Load balancer for test 2" id="lb-002" listener_count="1" name="api-loadbalancer-01" operating_status="ONLINE" pool_count="1" project_id="project-002" provider="octavia" provisioning_status="ACTIVE" vip_address="192.168.10.20"/> </data>
            ...      4     --exclude-name='web-loadbalancer-01'                                         OK: LoadBalancer count: 1 - LoadBalancer api-loadbalancer-01 has operating status ONLINE and privisioning status ACTIVE, Id: lb-002, Name: api-loadbalancer-01, Provisioning-status: ACTIVE, Admin-state-up: True, Vip-address: 192.168.10.20, Description: Load balancer for test 2, Provider: octavia, Project-id: project-002, pool-count : 1, listener-count : 1 | 'loadbalancer.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
            ...      5     --exclude-operating-status=ONLINE                                            OK: LoadBalancer count: 0 | 'loadbalancer.count'=0;;;0;
            ...      6     --exclude-provisioning-status=ACTIVE                                         OK: LoadBalancer count: 0 | 'loadbalancer.count'=0;;;0;
            ...      7     --include-description='test 1'                                               OK: LoadBalancer count: 1 - LoadBalancer web-loadbalancer-01 has operating status ONLINE and privisioning status ACTIVE, Id: lb-001, Name: web-loadbalancer-01, Provisioning-status: ACTIVE, Admin-state-up: True, Vip-address: 192.168.10.10, Description: Load balancer for test 1, Provider: octavia, Project-id: project-001, pool-count : 1, listener-count : 1 | 'loadbalancer.count'=1;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0;
            ...      8     --include-provider=octavia                                                   OK: LoadBalancer count: 2 - All load balancers are ok | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
            ...      9     --exclude-admin-state-up=false                                               OK: LoadBalancer count: 2 - All load balancers are ok | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
            ...      10    --exclude-vip-address=''                                                     OK: LoadBalancer count: 2 - All load balancers are ok | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
            ...      11    --include-id='lb-001'                                                        OK: LoadBalancer count: 1 - LoadBalancer web-loadbalancer-01 has operating status ONLINE and privisioning status ACTIVE, Id: lb-001, Name: web-loadbalancer-01, Provisioning-status: ACTIVE, Admin-state-up: True, Vip-address: 192.168.10.10, Description: Load balancer for test 1, Provider: octavia, Project-id: project-001, pool-count : 1, listener-count : 1 | 'loadbalancer.count'=1;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0;
            ...      12    --exclude-no-listeners --exclude-no-pools                                    OK: LoadBalancer count: 2 - All load balancers are ok | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
            ...      13    --warning-count=:1                                                           WARNING: LoadBalancer count: 2 | 'loadbalancer.count'=2;0:1;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
            ...      14    --warning-pool-count=:0                                                      WARNING: pool-count : 1 - pool-count : 1 | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;0:0;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;0:0;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
            ...      15    --warning-listener-count=:0                                                  WARNING: listener-count : 1 - listener-count : 1 | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;0:0;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;0:0;;0; 
            ...      16    --warning-name='%\\\{name\\\}=~/web-loadbalancer/'                           WARNING: Name: web-loadbalancer-01 | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
            ...      17    --warning-operating-status='%\\\{operating_status\\\} ne "ONLINE"'           OK: LoadBalancer count: 2 - All load balancers are ok | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
            ...      18    --warning-provisioning-status='%\\\{provisioning_status\\\} ne "ACTIVE"'     OK: LoadBalancer count: 2 - All load balancers are ok | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
            ...      19    --warning-description='%\\\{description\\\}=~/test 1/'                       WARNING: Description: Load balancer for test 1 | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
            ...      20    --critical-provider='%\\\{provider\\\} ne "octavia"'                         OK: LoadBalancer count: 2 - All load balancers are ok | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
            ...      21    --critical-admin-state-up='%\\\{admin_state_up\\\}=~/True/'                  CRITICAL: Admin-state-up: True - Admin-state-up: True | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
            ...      22    --critical-vip-address='%\\\{vip_address\\\}=~/192\.168\.10\.10/'            CRITICAL: Vip-address: 192.168.10.10 | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0; 
            ...      23    --critical-id='%\\\{id\\\}=~/lb-001/'                                        CRITICAL: Id: lb-001 | 'loadbalancer.count'=2;;;0; 'web-loadbalancer-01#pool.count'=1;;;0; 'web-loadbalancer-01#listener.count'=1;;;0; 'api-loadbalancer-01#pool.count'=1;;;0; 'api-loadbalancer-01#listener.count'=1;;;0;
