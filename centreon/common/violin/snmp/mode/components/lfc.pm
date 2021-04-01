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

package centreon::common::violin::snmp::mode::components::lfc;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_localTargetFcEntry = '.1.3.6.1.4.1.35897.1.2.1.6.1';
my $oid_wwn = '.1.3.6.1.4.1.35897.1.2.1.6.1.2';
my $oid_enable = '.1.3.6.1.4.1.35897.1.2.1.6.1.3';
my $oid_portState = '.1.3.6.1.4.1.35897.1.2.1.6.1.7';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_localTargetFcEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking local fc");
    $self->{components}->{lfc} = {name => 'local fc', total => 0, skip => 0};
    return if ($self->check_filter(section => 'lfc'));

    foreach my $oid (keys %{$self->{results}->{$oid_localTargetFcEntry}}) {
        next if ($oid !~ /^$oid_wwn\.(.*)$/);
        my $wwn = $self->{results}->{$oid_localTargetFcEntry}->{$oid};
        my $enable = $self->{results}->{$oid_localTargetFcEntry}->{$oid_enable . '.' .$1};
        my $state = $self->{results}->{$oid_localTargetFcEntry}->{$oid_portState . '.' .$1};

        if ($enable == 2) {
            $self->{output}->output_add(long_msg => sprintf("Skipping instance '$wwn' (not enable)"));
            next;
        }
        next if ($self->check_filter(section => 'lfc', instance => $wwn));
        
        $self->{components}->{lfc}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Local FC '%s' is %s.",
                                    $wwn, $state));
        my $exit = $self->get_severity(section => 'lfc', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Local FC '%s' is %s", $wwn, $state));
        }
    }
}

1;
