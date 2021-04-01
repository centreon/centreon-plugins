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

package centreon::common::violin::snmp::mode::components::ca;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_chassisSystemLedAlarm = '.1.3.6.1.4.1.35897.1.2.2.3.17.1.7';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_chassisSystemLedAlarm };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking chassis alarm");
    $self->{components}->{ca} = {name => 'chassis alarm', total => 0, skip => 0};
    return if ($self->check_filter(section => 'ca'));

    foreach my $oid (keys %{$self->{results}->{$oid_chassisSystemLedAlarm}}) {
        $oid =~ /^$oid_chassisSystemLedAlarm\.(.*)$/;
        my ($dummy, $array_name) = $self->convert_index(value => $1);
        my $instance = $array_name;
        my $ca_state = $self->{results}->{$oid_chassisSystemLedAlarm}->{$oid};

        next if ($self->check_filter(section => 'ca', instance => $instance));
        
        $self->{components}->{ca}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Chassis alarm '%s' is %s.",
                                    $instance, $ca_state));
        my $exit = $self->get_severity(section => 'ca', value => $ca_state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Chassis alarm '%s' is %s", $instance, $ca_state));
        }
    }
}

1;
