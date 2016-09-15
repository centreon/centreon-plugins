#
# Copyright 2016 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package apps::vmware::wsman::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $mapping_HealthState;
our $mapping_OperationalStatus;
our $mapping_EnableState;
our $mapping_units;
our $mapping_sensortype;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($mapping_HealthState $mapping_OperationalStatus $mapping_EnableState $mapping_units $mapping_sensortype);

$mapping_EnableState = {
    0 => 'Unknown',
    1 => 'Other',
    2 => 'Enabled',
    3 => 'Disabled',
    4 => 'Shutting Down',
    5 => 'Not Applicable',
    6 => 'Enabled but Offline',
    7 => 'In Test',
    8 => 'Deferred',
    9 => 'Quiesce',
    10 => 'Starting',
};

$mapping_HealthState = {
    0 => 'Unknown',
    5 => 'OK',
    10 => 'Degraded',
    15 => 'Minor failure',
    20 => 'Major failure',
    25 => 'Critical failure',
    30 => 'Non-recoverable error',
};

$mapping_OperationalStatus = {
    0 => 'Unknown', 
    1 => 'Other',
    2 => 'OK',
    3 => 'Degraded',
    4 => 'Stressed',
    5 => 'Predictive Failure',
    6 => 'Error',
    7 => 'Non-Recoverable Error',
    8 => 'Starting',
    9 => 'Stopping',
    10 => 'Stopped',
    11 => 'In Service',
    12 => 'No Contact',
    13 => 'Lost Communication',
    14 => 'Aborted',
    15 => 'Dormant',
    16 => 'Supporting Entity in Error',
    17 => 'Completed',
    18 => 'Power Mode',
    19 => 'Relocating',
};

$mapping_sensortype = {
    0 => 'unknown',
    1 => 'other',
    2 => 'temp', # Temperature
    3 => 'volt', # Voltage
    4 => 'current', # Current
    5 => 'tachometer',
    6 => 'counter',
    7 => 'switch',
    8 => 'lock',
    9 => 'hum', # Humidity
    10 => 'smoke_detection', # Smoke Detection
    11 => 'presence',
    12 => 'air_flow', # Air Flow
    13 => 'power_consumption', # Power Consumption
    14 => 'power_production', # Power Production
    15 => 'pressure_intrusion', # PressureIntrusion
    16 => 'intrusion',
};

$mapping_units = {
    0 => '',
    1 => '', 
    2 => 'C', # Degrees C 
    3 => 'F', # Degrees F
    4 => 'K', # Degrees K
    5 => 'V', # Volts 
    6 => 'A', # Amps, 
    7 => 'W', # Watts
    8 => 'Joules',
    9 => 'Coulombs', 
    10 => 'VA', 
    11 => 'Nits', 
    12 => 'Lumens',
    13 => 'Lux',
    14 => 'Candelas',
    15 => 'kPa',
    16 => 'PSI',
    17 => 'Newtons',
    18 => 'CFM',
    19 => 'rpm',
    20 => 'Hz', # Hertz
    21 => 'Seconds',
    22 => 'Minutes',
    23 => 'Hours',
    24 => 'Days',
    25 => 'Weeks',
    26 => 'Mils',
    27 => 'Inches',
    28 => 'Feet',
    29 => 'Cubic_Inches',
    30 => 'Cubic_Feet',
    31 => 'Meters',
    32 => 'Cubic_Centimeters',
    33 => 'Cubic_Meters',
    34 => 'Liters',
    35 => 'Fluid_Ounces',
    36 => 'Radians',
    37 => 'Steradians',
    38 => 'Revolutions',
    39 => 'Cycles',
    40 => 'Gravities',
    41 => 'Ounces',
    42 => 'Pounds',
    43 => 'Foot_Pounds',
    44 => 'Ounce_Inches',
    45 => 'Gauss',
    46 => 'Gilberts',
    47 => 'Henries',
    48 => 'Farads',
    49 => 'Ohms',
    50 => 'Siemens',
    51 => 'Moles',
    52 => 'Becquerels',
    53 => 'PPM',
    54 => 'Decibels',
    55 => 'DbA',
    56 => 'DbC',
    57 => 'Grays',
    58 => 'Sieverts',
    59 => 'Color_Temperature_Degrees_K',
    60 => 'b', # bits
    61 => 'B', # Bytes
    62 => 'Words',
    63 => 'DoubleWords',
    64 => 'QuadWords',
    65 => '%', # Percentage,
    66 => 'Pascals',
};

1;