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

package hardware::sensors::akcp::snmp::mode::components::serial;

use strict;
use warnings;
use hardware::sensors::akcp::snmp::mode::components::resources qw(%map_default2_status %map_online);

my $mapping = {
    hhmsSensorArraySerialDescription  => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.19.1.1' },
    hhmsSensorArraySerialStatus       => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.19.1.3', map => \%map_default2_status },
    hhmsSensorArraySerialOnline       => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.19.1.4', map => \%map_online },
};
my $oid_hhmsSensorArraySwitchEntry = '.1.3.6.1.4.1.3854.1.2.2.1.18.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_hhmsSensorArraySwitchEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking serials");
    $self->{components}->{serial} = {name => 'serials', total => 0, skip => 0};
    return if ($self->check_filter(section => 'serial'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_hhmsSensorArraySwitchEntry}})) {
        next if ($oid !~ /^$mapping->{hhmsSensorArraySerialOnline}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_hhmsSensorArraySwitchEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'serial', instance => $instance));
        if ($result->{hhmsSensorArraySerialOnline} eq 'offline') {
            $self->{output}->output_add(long_msg => sprintf("skipping '%s': is offline", $result->{hhmsSensorArraySerialDescription}));
            next;
        }
        $self->{components}->{serial}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("serial '%s' status is '%s' [instance = %s]",
                                    $result->{hhmsSensorArraySerialDescription}, $result->{hhmsSensorArraySerialStatus}, $instance, 
                                    ));
        
        my $exit = $self->get_severity(label => 'default2', section => 'serial', value => $result->{hhmsSensorArraySerialStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Serial '%s' status is '%s'", $result->{hhmsSensorArraySerialDescription}, $result->{hhmsSensorArraySerialStatus}));
        }
    }
}

1;
