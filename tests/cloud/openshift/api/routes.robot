*** Settings ***
Documentation       cloud::openshift::api::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}openshift.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::openshift::api::plugin
...                 --mode=routes
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --token=fake-token


*** Test Cases ***
Routes ${tc}
    [Tags]    cloud    openshift    api
    ${command}    Catenate
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
    ...    OK: Total routes: 5, Routes admitted: 5, Routes not admitted: 0, Routes with TLS: 5, Routes without TLS: 0, Hosts exposed: 5, Services targeted: 5 | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    2
    ...    --include-name=oauth-openshift
    ...    OK: Total routes: 1, Routes admitted: 1, Routes not admitted: 0, Routes with TLS: 1, Routes without TLS: 0, Hosts exposed: 1, Services targeted: 1 - Namespace openshift-authentication: 1 route(s) - Termination passthrough: 1 route(s) | 'routes-total'=1;;;0; 'routes-admitted'=1;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=1;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=1;;;0; 'services-targeted'=1;;;0; 'routes-per-namespace'=1;;;0; 'termination-type'=1;;;0;
    ...    3
    ...    --exclude-name=oauth-openshift
    ...    OK: Total routes: 4, Routes admitted: 4, Routes not admitted: 0, Routes with TLS: 4, Routes without TLS: 0, Hosts exposed: 4, Services targeted: 4 | 'routes-total'=4;;;0; 'routes-admitted'=4;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=4;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=4;;;0; 'services-targeted'=4;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=1;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    4
    ...    --include-namespace=openshift-authentication
    ...    OK: Total routes: 1, Routes admitted: 1, Routes not admitted: 0, Routes with TLS: 1, Routes without TLS: 0, Hosts exposed: 1, Services targeted: 1 - Namespace openshift-authentication: 1 route(s) - Termination passthrough: 1 route(s) | 'routes-total'=1;;;0; 'routes-admitted'=1;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=1;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=1;;;0; 'services-targeted'=1;;;0; 'routes-per-namespace'=1;;;0; 'termination-type'=1;;;0;
    ...    5
    ...    --exclude-namespace=openshift-authentication
    ...    OK: Total routes: 4, Routes admitted: 4, Routes not admitted: 0, Routes with TLS: 4, Routes without TLS: 0, Hosts exposed: 4, Services targeted: 4 | 'routes-total'=4;;;0; 'routes-admitted'=4;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=4;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=4;;;0; 'services-targeted'=4;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=1;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    6
    ...    --include-host=console-openshift-console.apps-crc.testing
    ...    OK: Total routes: 1, Routes admitted: 1, Routes not admitted: 0, Routes with TLS: 1, Routes without TLS: 0, Hosts exposed: 1, Services targeted: 1 - Namespace openshift-console: 1 route(s) - Termination reencrypt: 1 route(s) | 'routes-total'=1;;;0; 'routes-admitted'=1;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=1;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=1;;;0; 'services-targeted'=1;;;0; 'routes-per-namespace'=1;;;0; 'termination-type'=1;;;0;
    ...    7
    ...    --exclude-host=console-openshift-console.apps-crc.testing
    ...    OK: Total routes: 4, Routes admitted: 4, Routes not admitted: 0, Routes with TLS: 4, Routes without TLS: 0, Hosts exposed: 4, Services targeted: 4 | 'routes-total'=4;;;0; 'routes-admitted'=4;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=4;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=4;;;0; 'services-targeted'=4;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=1;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=1;;;0;
    ...    8
    ...    --include-label=app=oauth-openshift
    ...    OK: Total routes: 1, Routes admitted: 1, Routes not admitted: 0, Routes with TLS: 1, Routes without TLS: 0, Hosts exposed: 1, Services targeted: 1 - Namespace openshift-authentication: 1 route(s) - Termination passthrough: 1 route(s) | 'routes-total'=1;;;0; 'routes-admitted'=1;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=1;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=1;;;0; 'services-targeted'=1;;;0; 'routes-per-namespace'=1;;;0; 'termination-type'=1;;;0;
    ...    9
    ...    --exclude-label=app=oauth-openshift
    ...    OK: Total routes: 4, Routes admitted: 4, Routes not admitted: 0, Routes with TLS: 4, Routes without TLS: 0, Hosts exposed: 4, Services targeted: 4 | 'routes-total'=4;;;0; 'routes-admitted'=4;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=4;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=4;;;0; 'services-targeted'=4;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=1;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    10
    ...    --include-service=downloads
    ...    OK: Total routes: 1, Routes admitted: 1, Routes not admitted: 0, Routes with TLS: 1, Routes without TLS: 0, Hosts exposed: 1, Services targeted: 1 - Namespace openshift-console: 1 route(s) - Termination edge: 1 route(s) | 'routes-total'=1;;;0; 'routes-admitted'=1;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=1;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=1;;;0; 'services-targeted'=1;;;0; 'routes-per-namespace'=1;;;0; 'termination-type'=1;;;0;
    ...    11
    ...    --exclude-service=downloads
    ...    OK: Total routes: 4, Routes admitted: 4, Routes not admitted: 0, Routes with TLS: 4, Routes without TLS: 0, Hosts exposed: 4, Services targeted: 4 | 'routes-total'=4;;;0; 'routes-admitted'=4;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=4;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=4;;;0; 'services-targeted'=4;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=1;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    12
    ...    --include-termination=edge
    ...    OK: Total routes: 1, Routes admitted: 1, Routes not admitted: 0, Routes with TLS: 1, Routes without TLS: 0, Hosts exposed: 1, Services targeted: 1 - Namespace openshift-console: 1 route(s) - Termination edge: 1 route(s) | 'routes-total'=1;;;0; 'routes-admitted'=1;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=1;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=1;;;0; 'services-targeted'=1;;;0; 'routes-per-namespace'=1;;;0; 'termination-type'=1;;;0;
    ...    13
    ...    --exclude-termination=edge
    ...    OK: Total routes: 4, Routes admitted: 4, Routes not admitted: 0, Routes with TLS: 4, Routes without TLS: 0, Hosts exposed: 4, Services targeted: 4 | 'routes-total'=4;;;0; 'routes-admitted'=4;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=4;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=4;;;0; 'services-targeted'=4;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=1;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    14
    ...    --warning-hosts-exposed=1
    ...    WARNING: Hosts exposed: 5 | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;0:1;;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    15
    ...    --critical-hosts-exposed=1
    ...    CRITICAL: Hosts exposed: 5 | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;;0:1;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    16
    ...    --warning-routes-admitted=@1 --include-name=canary
    ...    WARNING: Routes admitted: 1 | 'routes-total'=1;;;0; 'routes-admitted'=1;@0:1;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=1;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=1;;;0; 'services-targeted'=1;;;0; 'routes-per-namespace'=1;;;0; 'termination-type'=1;;;0; List of admitted routes: Route 'canary' [namespace: openshift-ingress-canary, host: canary-openshift-ingress-canary.apps-crc.testing, service: ingress-canary]
    ...    17
    ...    --critical-routes-admitted=@1 --include-namespace=openshift-ingress-canary
    ...    CRITICAL: Routes admitted: 1 | 'routes-total'=1;;;0; 'routes-admitted'=1;;@0:1;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=1;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=1;;;0; 'services-targeted'=1;;;0; 'routes-per-namespace'=1;;;0; 'termination-type'=1;;;0; List of admitted routes: Route 'canary' [namespace: openshift-ingress-canary, host: canary-openshift-ingress-canary.apps-crc.testing, service: ingress-canary]
    ...    18
    ...    --warning-routes-not-admitted=@0
    ...    WARNING: Routes not admitted: 0 | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;@0:0;;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    19
    ...    --critical-routes-not-admitted=@0
    ...    CRITICAL: Routes not admitted: 0 | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;@0:0;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    20
    ...    --warning-routes-not-tls=@0
    ...    WARNING: Routes without TLS: 0 | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;@0:0;;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    21
    ...    --critical-routes-not-tls=@0
    ...    CRITICAL: Routes without TLS: 0 | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;;@0:0;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    22
    ...    --warning-routes-per-namespace=1
    ...    WARNING: Namespace openshift-console: 2 route(s) | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;0:1;;0; 'routes-per-namespace_openshift-console'=2;0:1;;0; 'routes-per-namespace_openshift-image-registry'=1;0:1;;0; 'routes-per-namespace_openshift-ingress-canary'=1;0:1;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    23
    ...    --critical-routes-per-namespace=1
    ...    CRITICAL: Namespace openshift-console: 2 route(s) | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;;0:1;0; 'routes-per-namespace_openshift-console'=2;;0:1;0; 'routes-per-namespace_openshift-image-registry'=1;;0:1;0; 'routes-per-namespace_openshift-ingress-canary'=1;;0:1;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    24
    ...    --warning-routes-tls=1
    ...    WARNING: Routes with TLS: 5 | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;0:1;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0; List of routes with TLS: Route 'canary' [namespace: openshift-ingress-canary, host: canary-openshift-ingress-canary.apps-crc.testing, service: ingress-canary] Route 'console' [namespace: openshift-console, host: console-openshift-console.apps-crc.testing, service: console] Route 'default-route' [namespace: openshift-image-registry, host: default-route-openshift-image-registry.apps-crc.testing, service: image-registry] Route 'downloads' [namespace: openshift-console, host: downloads-openshift-console.apps-crc.testing, service: downloads] Route 'oauth-openshift' [namespace: openshift-authentication, host: oauth-openshift.apps-crc.testing, service: oauth-openshift]
    ...    25
    ...    --critical-routes-tls=1
    ...    CRITICAL: Routes with TLS: 5 | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;;0:1;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0; List of routes with TLS: Route 'canary' [namespace: openshift-ingress-canary, host: canary-openshift-ingress-canary.apps-crc.testing, service: ingress-canary] Route 'console' [namespace: openshift-console, host: console-openshift-console.apps-crc.testing, service: console] Route 'default-route' [namespace: openshift-image-registry, host: default-route-openshift-image-registry.apps-crc.testing, service: image-registry] Route 'downloads' [namespace: openshift-console, host: downloads-openshift-console.apps-crc.testing, service: downloads] Route 'oauth-openshift' [namespace: openshift-authentication, host: oauth-openshift.apps-crc.testing, service: oauth-openshift]
    ...    26
    ...    --warning-routes-total=1
    ...    WARNING: Total routes: 5 | 'routes-total'=5;0:1;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    27
    ...    --critical-routes-total=1
    ...    CRITICAL: Total routes: 5 | 'routes-total'=5;;0:1;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    28
    ...    --warning-services-targeted=1
    ...    WARNING: Services targeted: 5 | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;0:1;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    29
    ...    --critical-services-targeted=1
    ...    CRITICAL: Services targeted: 5 | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;;0:1;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;;0; 'termination-type_passthrough'=2;;;0; 'termination-type_reencrypt'=2;;;0;
    ...    30
    ...    --warning-termination-type=1
    ...    WARNING: Termination passthrough: 2 route(s) - Termination reencrypt: 2 route(s) | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;0:1;;0; 'termination-type_passthrough'=2;0:1;;0; 'termination-type_reencrypt'=2;0:1;;0;
    ...    31
    ...    --critical-termination-type=1
    ...    CRITICAL: Termination passthrough: 2 route(s) - Termination reencrypt: 2 route(s) | 'routes-total'=5;;;0; 'routes-admitted'=5;;;0; 'routes-not-admitted'=0;;;0; 'routes-tls'=5;;;0; 'routes-not-tls'=0;;;0; 'hosts-exposed'=5;;;0; 'services-targeted'=5;;;0; 'routes-per-namespace_openshift-authentication'=1;;;0; 'routes-per-namespace_openshift-console'=2;;;0; 'routes-per-namespace_openshift-image-registry'=1;;;0; 'routes-per-namespace_openshift-ingress-canary'=1;;;0; 'termination-type_edge'=1;;0:1;0; 'termination-type_passthrough'=2;;0:1;0; 'termination-type_reencrypt'=2;;0:1;0;
