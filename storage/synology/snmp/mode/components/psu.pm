#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package storage::synology::snmp::mode::components::psu;

use strict;
use warnings;

my %map_status = (1 => 'Normal', 2 => 'Failed');

my $mapping = {
    synoSystempowerStatus => { oid => '.1.3.6.1.4.1.6574.1.3', map => \%map_status  },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{synoSystempowerStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supply");
    $self->{components}->{psu} = {name => 'psu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));
    $self->{components}->{psu}->{total}++;

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{synoSystempowerStatus}->{oid}}, instance => '0');
    $self->{output}->output_add(long_msg => sprintf("power supply status is %s.",
                                    $result->{synoSystempowerStatus}));
    my $exit = $self->get_severity(label => 'default', section => 'psu', value => $result->{synoSystempowerStatus});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Power Supply status is %s.", $result->{synoSystempowerStatus}));
    }
}

1;