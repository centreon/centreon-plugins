*** Settings ***
Documentation       hardware::devices::camera::mobotix::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...        --plugin=hardware::devices::camera::mobotix::snmp::plugin
...        --mode=system
...        --hostname=${HOSTNAME}
...        --snmp-port=${SNMPPORT}
...        --snmp-version=${SNMPVERSION}
...        --snmp-community=hardware/devices/camera/mobotix/snmp/mobotix

*** Test Cases ***
System ${tc}
    [Tags]    hardware    devices    snmp
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
    ...    OK: internal temperature: 14 C - external temperature: 14 C - gps temperature: 10 C - illumination right: 1355 lx - illumination left: 10 lx - video framerate: 2 fps | 'system.temperature.internal.celsius'=14C;;;; 'system.temperature.external.celsius'=14C;;;; 'system.temperature.gps.celsius'=10C;;;; 'system.illumination.right.lux'=1355lx;;;; 'system.illumination.left.lux'=10lx;;;; 'system.video.framerate.persecond'=2fps;;;;
    ...    2
    ...    --unavailable-sdcard-status=critical
    ...    CRITICAL: SD card not available | 'system.temperature.internal.celsius'=14C;;;; 'system.temperature.external.celsius'=14C;;;; 'system.temperature.gps.celsius'=10C;;;; 'system.illumination.right.lux'=1355lx;;;; 'system.illumination.left.lux'=10lx;;;; 'system.video.framerate.persecond'=2fps;;;;
    ...    3
    ...    --warning-illumination-left=:1
    ...    WARNING: illumination left: 10 lx | 'system.temperature.internal.celsius'=14C;;;; 'system.temperature.external.celsius'=14C;;;; 'system.temperature.gps.celsius'=10C;;;; 'system.illumination.right.lux'=1355lx;;;; 'system.illumination.left.lux'=10lx;0:1;;; 'system.video.framerate.persecond'=2fps;;;;
    ...    4
    ...    --critical-illumination-left=:1
    ...    CRITICAL: illumination left: 10 lx | 'system.temperature.internal.celsius'=14C;;;; 'system.temperature.external.celsius'=14C;;;; 'system.temperature.gps.celsius'=10C;;;; 'system.illumination.right.lux'=1355lx;;;; 'system.illumination.left.lux'=10lx;;0:1;; 'system.video.framerate.persecond'=2fps;;;;
    ...    5
    ...    --warning-illumination-right=:1
    ...    WARNING: illumination right: 1355 lx | 'system.temperature.internal.celsius'=14C;;;; 'system.temperature.external.celsius'=14C;;;; 'system.temperature.gps.celsius'=10C;;;; 'system.illumination.right.lux'=1355lx;0:1;;; 'system.illumination.left.lux'=10lx;;;; 'system.video.framerate.persecond'=2fps;;;;
    ...    6
    ...    --critical-illumination-right=:1
    ...    CRITICAL: illumination right: 1355 lx | 'system.temperature.internal.celsius'=14C;;;; 'system.temperature.external.celsius'=14C;;;; 'system.temperature.gps.celsius'=10C;;;; 'system.illumination.right.lux'=1355lx;;0:1;; 'system.illumination.left.lux'=10lx;;;; 'system.video.framerate.persecond'=2fps;;;;
    ...    7
    ...    --warning-temperature-external=:1
    ...    WARNING: external temperature: 14 C | 'system.temperature.internal.celsius'=14C;;;; 'system.temperature.external.celsius'=14C;0:1;;; 'system.temperature.gps.celsius'=10C;;;; 'system.illumination.right.lux'=1355lx;;;; 'system.illumination.left.lux'=10lx;;;; 'system.video.framerate.persecond'=2fps;;;;
    ...    8
    ...    --critical-temperature-external=:1
    ...    CRITICAL: external temperature: 14 C | 'system.temperature.internal.celsius'=14C;;;; 'system.temperature.external.celsius'=14C;;0:1;; 'system.temperature.gps.celsius'=10C;;;; 'system.illumination.right.lux'=1355lx;;;; 'system.illumination.left.lux'=10lx;;;; 'system.video.framerate.persecond'=2fps;;;;
    ...    9
    ...    --warning-temperature-gps=:1
    ...    WARNING: gps temperature: 10 C | 'system.temperature.internal.celsius'=14C;;;; 'system.temperature.external.celsius'=14C;;;; 'system.temperature.gps.celsius'=10C;0:1;;; 'system.illumination.right.lux'=1355lx;;;; 'system.illumination.left.lux'=10lx;;;; 'system.video.framerate.persecond'=2fps;;;;
    ...    10
    ...    --critical-temperature-gps=:1
    ...    CRITICAL: gps temperature: 10 C | 'system.temperature.internal.celsius'=14C;;;; 'system.temperature.external.celsius'=14C;;;; 'system.temperature.gps.celsius'=10C;;0:1;; 'system.illumination.right.lux'=1355lx;;;; 'system.illumination.left.lux'=10lx;;;; 'system.video.framerate.persecond'=2fps;;;; 
    ...    11
    ...    --warning-temperature-internal=:1
    ...    WARNING: internal temperature: 14 C | 'system.temperature.internal.celsius'=14C;0:1;;; 'system.temperature.external.celsius'=14C;;;; 'system.temperature.gps.celsius'=10C;;;; 'system.illumination.right.lux'=1355lx;;;; 'system.illumination.left.lux'=10lx;;;; 'system.video.framerate.persecond'=2fps;;;;
    ...    12
    ...    --critical-temperature-internal=:1
    ...    CRITICAL: internal temperature: 14 C | 'system.temperature.internal.celsius'=14C;;0:1;; 'system.temperature.external.celsius'=14C;;;; 'system.temperature.gps.celsius'=10C;;;; 'system.illumination.right.lux'=1355lx;;;; 'system.illumination.left.lux'=10lx;;;; 'system.video.framerate.persecond'=2fps;;;;
    ...    13
    ...    --warning-video-framerate=:1
    ...    WARNING: video framerate: 2 fps | 'system.temperature.internal.celsius'=14C;;;; 'system.temperature.external.celsius'=14C;;;; 'system.temperature.gps.celsius'=10C;;;; 'system.illumination.right.lux'=1355lx;;;; 'system.illumination.left.lux'=10lx;;;; 'system.video.framerate.persecond'=2fps;0:1;;;
    ...    14
    ...    --critical-video-framerate=:1
    ...    CRITICAL: video framerate: 2 fps | 'system.temperature.internal.celsius'=14C;;;; 'system.temperature.external.celsius'=14C;;;; 'system.temperature.gps.celsius'=10C;;;; 'system.illumination.right.lux'=1355lx;;;; 'system.illumination.left.lux'=10lx;;;; 'system.video.framerate.persecond'=2fps;;0:1;;
