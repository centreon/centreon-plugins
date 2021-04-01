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

package centreon::common::violin::snmp::mode::components::gfc;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_globalTargetFcEntry = '.1.3.6.1.4.1.35897.1.2.1.10.1';
my $oid_wwn = '.1.3.6.1.4.1.35897.1.2.1.10.1.3';
my $oid_enable = '.1.3.6.1.4.1.35897.1.2.1.10.1.4';
my $oid_portState = '.1.3.6.1.4.1.35897.1.2.1.10.1.8';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_globalTargetFcEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking global fc");
    $self->{components}->{gfc} = {name => 'global fc', total => 0, skip => 0};
    return if ($self->check_filter(section => 'gfc'));

    foreach my $oid (keys %{$self->{results}->{$oid_globalTargetFcEntry}}) {
        next if ($oid !~ /^$oid_wwn\.(.*)$/);
        my $wwn = $self->{results}->{$oid_globalTargetFcEntry}->{$oid};
        my $enable = $self->{results}->{$oid_globalTargetFcEntry}->{$oid_enable . '.' .$1};
        my $state = $self->{results}->{$oid_globalTargetFcEntry}->{$oid_portState . '.' .$1};

        if ($enable == 2) {
            $self->{output}->output_add(long_msg => sprintf("Skipping instance '$wwn' (not enable)"));
            next;
        }
        next if ($self->check_filter(section => 'gfc', instance => $wwn));
        
        $self->{components}->{gfc}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Global FC '%s' is %s.",
                                    $wwn, $state));
        my $exit = $self->get_severity(section => 'gfc', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Global FC '%s' is %s", $wwn, $state));
        }
    }
}

1;
