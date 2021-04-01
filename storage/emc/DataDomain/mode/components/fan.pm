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

package storage::emc::DataDomain::mode::components::fan;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_fan_status = (
    0 => 'notfound',
    1 => 'ok',
    2 => 'failed',
);
my %level_map = ( 
    0 => 'unknown',
    1 => 'low',
    2 => 'normal',
    3 => 'high',
); 

my ($oid_fanDescription, $oid_fanLevel, $oid_fanStatus);
my $oid_fanPropertiesEntry = '.1.3.6.1.4.1.19746.1.1.3.1.1.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_fanPropertiesEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));
    
    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.x')) {
        $oid_fanDescription = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.4';
        $oid_fanLevel = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.5';
        $oid_fanStatus = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.6';
    } else {
        $oid_fanDescription = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.3';
        $oid_fanLevel = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.4';
        $oid_fanStatus = '.1.3.6.1.4.1.19746.1.1.3.1.1.1.5';
    }

    foreach my $oid (keys %{$self->{results}->{$oid_fanPropertiesEntry}}) {
        next if ($oid !~ /^$oid_fanStatus\.(.*)$/);
        my $instance = $1;
        my $fan_descr = centreon::plugins::misc::trim($self->{results}->{$oid_fanPropertiesEntry}->{$oid_fanDescription . '.' . $instance});
        my $fan_status = defined($map_fan_status{$self->{results}->{$oid_fanPropertiesEntry}->{$oid}}) ?
                            $map_fan_status{$self->{results}->{$oid_fanPropertiesEntry}->{$oid}} : 'unknown';
        my $fan_level = $self->{results}->{$oid_fanPropertiesEntry}->{$oid_fanLevel . '.' . $instance};

        next if ($self->check_filter(section => 'fan', instance => $instance));
        next if ($fan_status =~ /notfound/i && 
                 $self->absent_problem(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' status is '%s' [instance = %s, level = %s]",
                                    $fan_descr, $fan_status, $instance, $level_map{$fan_level}));
        my $exit = $self->get_severity(section => 'fan', value => $fan_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' status is '%s'", $fan_descr, $fan_status));
        }
    }
}

1;