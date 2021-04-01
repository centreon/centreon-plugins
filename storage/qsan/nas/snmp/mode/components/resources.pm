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

package storage::qsan::nas::snmp::mode::components::resources;

use strict;
use warnings;
use Exporter;

our $mapping;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw($mapping);

$mapping = {
    ems_type    => { oid => '.1.3.6.1.4.1.22274.2.3.2.1.2' },
    ems_item    => { oid => '.1.3.6.1.4.1.22274.2.3.2.1.3' },
    ems_value   => { oid => '.1.3.6.1.4.1.22274.2.3.2.1.4' },
    ems_status  => { oid => '.1.3.6.1.4.1.22274.2.3.2.1.5' },
};

sub load_monitor {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $mapping->{ems_type}->{oid} },
        { oid => $mapping->{ems_item}->{oid} }, { oid => $mapping->{ems_value}->{oid} },
        { oid => $mapping->{ems_status}->{oid} };
}

1;
