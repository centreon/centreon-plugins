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

package centreon::common::violin::snmp::mode::components::vimm;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_arrayVimmEntry_present = '.1.3.6.1.4.1.35897.1.2.2.3.16.1.4';
my $oid_arrayVimmEntry_failed = '.1.3.6.1.4.1.35897.1.2.2.3.16.1.10';

my %map_vimm_state = (
    1 => 'failed',
    2 => 'not failed',
);

my %map_vimm_present = (
    1 => 'present',
    2 => 'absent',
);

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_arrayVimmEntry_present }, { oid => $oid_arrayVimmEntry_failed };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking vimms");
    $self->{components}->{vimm} = {name => 'vimms', total => 0, skip => 0};
    return if ($self->check_filter(section => 'vimm'));

    foreach my $oid (keys %{$self->{results}->{$oid_arrayVimmEntry_present}}) {
        next if ($oid !~ /^$oid_arrayVimmEntry_present\.(.*)$/);
        my $state = $self->{results}->{$oid_arrayVimmEntry_failed}->{$oid_arrayVimmEntry_failed . '.' . $1};
        my $present = $self->{results}->{$oid_arrayVimmEntry_present}->{$oid};
        my ($dummy, $array_name, $vimm_name) = $self->convert_index(value => $1);
        my $instance = $array_name . '-' . $vimm_name;

        next if ($self->check_filter(section => 'vimm', instance => $instance));
        next if ($map_vimm_present{$present} =~ /Absent/i && 
                 $self->absent_problem(section => 'vimm', instance => $instance));
        
        $self->{components}->{vimm}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Vimm '%s' is %s.",
                                    $instance, $map_vimm_state{$state}));
        my $exit = $self->get_severity(section => 'vimm', value => $map_vimm_state{$state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Vimm '%s' is %s", $instance, $map_vimm_state{$state}));
        }
    }
}

1;
