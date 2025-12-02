#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::evertz::FC7800::snmp::mode::components::psu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_psu_status = (1 => 'false', 2 => 'true', 3 => 'notAvailable');

my $mapping_psu = {
    powerSupply1Status    => { oid => '.1.3.6.1.4.1.6827.10.232.4.3', map => \%map_psu_status },
    powerSupply2Status    => { oid => '.1.3.6.1.4.1.6827.10.232.4.4', map => \%map_psu_status },
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, $mapping_psu->{powerSupply1Status}->{oid} . '.0', $mapping_psu->{powerSupply2Status}->{oid} . '.0';
}

sub check_psu {
    my ($self, %options) = @_;

    return if (!defined($options{status}));
    return if ($self->check_filter(section => 'psu', instance => $options{instance}));

    $self->{components}->{psu}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("power supply '%s' status is '%s' [instance = %s]",
                                                    $options{instance}, $options{status}, $options{instance}));
    my $exit = $self->get_severity(section => 'psu', value => $options{status});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Power supply '%s' status is '%s'", $options{instance}, $options{status}));
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking poer supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping_psu, results => $self->{results}, instance => '0');

    check_psu($self, status => $result->{powerSupply1Status}, instance => 1);
    check_psu($self, status => $result->{powerSupply2Status}, instance => 2);
}

1;