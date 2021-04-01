#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package hardware::pdu::schleifenbauer::gateway::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $oid_pdumeasuresEntry;
our $oid_deviceName;
our $mapping;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($oid_pdumeasuresEntry $oid_deviceName $mapping);

$oid_pdumeasuresEntry = '.1.3.6.1.4.1.31034.1.1.8.1';
$oid_deviceName = '.1.3.6.1.4.1.31034.1.1.4.1.3';

$mapping = {
    pduIntTemperature   => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.3' },
    pduExtTemperature   => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.4' },
    sensor1Type         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.7' },
    sensor1Value        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.8' },
    sensor1Name         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.9' },
    sensor2Type         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.10' },
    sensor2Value        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.11' },
    sensor2Name         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.12' },
    sensor3Type         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.13' },
    sensor3Value        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.14' },
    sensor3Name         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.15' },
    sensor4Type         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.16' },
    sensor4Value        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.17' },
    sensor4Name         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.18' },
    sensor5Type         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.19' },
    sensor5Value        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.20' },
    sensor5Name         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.21' },
    sensor6Type         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.22' },
    sensor6Value        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.23' },
    sensor6Name         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.24' },
    sensor7Type         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.25' },
    sensor7Value        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.26' },
    sensor7Name         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.27' },
    sensor8Type         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.28' },
    sensor8Value        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.29' },
    sensor8Name         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.30' },
    sensor9Type         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.31' },
    sensor9Value        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.32' },
    sensor9Name         => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.33' },
    sensor10Type        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.34' },
    sensor10Value       => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.35' },
    sensor10Name        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.36' },
    sensor11Type        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.37' },
    sensor11Value       => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.38' },
    sensor11Name        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.39' },
    sensor12Type        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.40' },
    sensor12Value       => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.41' },
    sensor12Name        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.42' },
    sensor13Type        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.43' },
    sensor13Value       => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.44' },
    sensor13Name        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.45' },
    sensor14Type        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.46' },
    sensor14Value       => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.47' },
    sensor14Name        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.48' },
    sensor15Type        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.49' },
    sensor15Value       => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.50' },
    sensor15Name        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.51' },
    sensor16Type        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.52' },
    sensor16Value       => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.53' },
    sensor16Name        => { oid => '.1.3.6.1.4.1.31034.1.1.8.1.54' },
};

1;
