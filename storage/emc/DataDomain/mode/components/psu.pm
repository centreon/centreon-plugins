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

package storage::emc::DataDomain::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = ();
my ($oid_powerModuleDescription, $oid_powerModuleStatus);
my $oid_powerModuleEntry = '.1.3.6.1.4.1.19746.1.1.1.1.1.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_powerModuleEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));
    
    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.x')) {
        $oid_powerModuleDescription = '.1.3.6.1.4.1.19746.1.1.1.1.1.1.3';
        $oid_powerModuleStatus = '.1.3.6.1.4.1.19746.1.1.1.1.1.1.4';
        %map_psu_status = (0 => 'absent', 1 => 'ok', 2 => 'failed', 3 => 'faulty', 4 => 'acnone',
                           99 => 'unknown');
    } else {
        $oid_powerModuleDescription = ''; # none
        $oid_powerModuleStatus = '.1.3.6.1.4.1.19746.1.1.1.1.1.1.4';
        %map_psu_status = (1 => 'ok', 2 => 'unknown', 3 => 'failed');
    }

    foreach my $oid (keys %{$self->{results}->{$oid_powerModuleEntry}}) {
        next if ($oid !~ /^$oid_powerModuleStatus\.(.*)$/);
        my $instance = $1;
        my $psu_descr = defined($self->{results}->{$oid_powerModuleEntry}->{$oid_powerModuleDescription . '.' . $instance}) ? 
                            centreon::plugins::misc::trim($self->{results}->{$oid_powerModuleEntry}->{$oid_powerModuleDescription . '.' . $instance}) : 'unknown';
        my $psu_status = defined($map_psu_status{$self->{results}->{$oid_powerModuleEntry}->{$oid}}) ?
                            $map_psu_status{$self->{results}->{$oid_powerModuleEntry}->{$oid}} : 'unknown';

        next if ($self->check_filter(section => 'psu', instance => $instance));
        next if ($psu_status =~ /absent/i && 
                 $self->absent_problem(section => 'psu', instance => $instance));
        
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power Supply '%s' status is '%s' [description = %s]",
                                    $instance, $psu_status, $instance));
        my $exit = $self->get_severity(section => 'psu', value => $psu_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power Supply '%s' status is '%s'", $instance, $psu_status));
        }
    }
}

1;