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

package network::mikrotik::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $map_gauge_unit;
our $mapping_gauge;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($map_gauge_unit $mapping_gauge);

$mapping_gauge = {
    name  => { oid => '.1.3.6.1.4.1.14988.1.1.3.100.1.2' }, # mtxrGaugeName
    value => { oid => '.1.3.6.1.4.1.14988.1.1.3.100.1.3' }, # mtxrGaugeName
    unit  => { oid => '.1.3.6.1.4.1.14988.1.1.3.100.1.4' }  # mtxrGaugeUnit
};

$map_gauge_unit = {
    1 => 'celsius',
    2 => 'rpm',
    3 => 'dV',
    4 => 'dA',
    5 => 'dW',
    6 => 'status'
};

1;
