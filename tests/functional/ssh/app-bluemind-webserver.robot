*** Settings ***
Documentation       AWS CloudTrail plugin

Library             OperatingSystem
Library             Process
Library             String

Suite Setup         Start Mockoon
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${CENTREON_PLUGINS}             ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl

${CMD}                          perl ${CENTREON_PLUGINS} --plugin=cloud::apps::bluemind::local::plugin --mode=webserver --hostname='127.0.0.1'

