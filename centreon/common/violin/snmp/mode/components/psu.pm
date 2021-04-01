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

package centreon::common::violin::snmp::mode::components::psu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_chassisSystemPowerPSUA = '.1.3.6.1.4.1.35897.1.2.2.3.17.1.17';
my $oid_chassisSystemPowerPSUB = '.1.3.6.1.4.1.35897.1.2.2.3.17.1.18';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_chassisSystemPowerPSUA }, { oid => $oid_chassisSystemPowerPSUB };
}

sub psu {
    my ($self, %options) = @_;
    my $oid = $options{oid};
    
    $options{oid} =~ /^$options{oid_short}\.(.*)$/;
    my ($dummy, $array_name) = $self->convert_index(value => $1);
    my $instance = $array_name . '-' . $options{extra_instance};
    
    my $psu_state = $options{value};

    return if ($self->check_filter(section => 'psu', instance => $instance));
    return if ($psu_state =~ /Absent/i && 
               $self->absent_problem(section => 'psu', instance => $instance));
        
    $self->{components}->{psu}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("Power Supply '%s' status is %s.",
                                $instance, $psu_state));
    my $exit = $self->get_severity(section => 'psu', value => $psu_state);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Power Supply '%s' status is %s", $instance, $psu_state));
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));
    
    foreach my $oid (keys %{$self->{results}->{$oid_chassisSystemPowerPSUA}}) {
        psu($self, oid => $oid, oid_short => $oid_chassisSystemPowerPSUA, value => $self->{results}->{$oid_chassisSystemPowerPSUA}->{$oid},
            extra_instance => 'A');
    }
    foreach my $oid (keys %{$self->{results}->{$oid_chassisSystemPowerPSUB}}) {
        psu($self, oid => $oid, oid_short => $oid_chassisSystemPowerPSUB, value => $self->{results}->{$oid_chassisSystemPowerPSUB}->{$oid},
            extra_instance => 'B');
    }
}

1;
