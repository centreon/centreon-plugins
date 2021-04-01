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

package hardware::server::ibm::bladecenter::snmp::mode::components::fanpack;

use strict;
use warnings;

my %map_state = (
    0 => 'unknown', 
    1 => 'good', 
    2 => 'warning', 
    3 => 'bad',
);
my %map_exists = (
    0 => 'false',
    1 => 'true',
);

# In MIB 'mmblade.mib' and 'cme.mib'
my $mapping = {
    fanPackExists => { oid => '.1.3.6.1.4.1.2.3.51.2.2.6.1.1.2', map => \%map_exists },
    fanPackState => { oid => '.1.3.6.1.4.1.2.3.51.2.2.6.1.1.3', map => \%map_state },
    fanPackAverageSpeedRPM => { oid => '.1.3.6.1.4.1.2.3.51.2.2.6.1.1.6' },
};
my $oid_fanPackEntry = '.1.3.6.1.4.1.2.3.51.2.2.6.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_fanPackEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fanpack");
    $self->{components}->{fanpack} = {name => 'fanpacks', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fanpack'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fanPackEntry}})) {
        next if ($oid !~ /^$mapping->{fanPackState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fanPackEntry}, instance => $instance);
        
        if ($result->{fanPackExists} =~ /false/i) {
            $self->{output}->output_add(long_msg => "skipping fanpack '" . $instance . "' : not exits"); 
            next;
        }
        next if ($self->check_filter(section => 'fanpack', instance => $instance));
        $self->{components}->{fanpack}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Fanpack '%s' is %s rpm [status: %s, instance: %s]", 
                                    $instance, $result->{fanPackAverageSpeedRPM}, $result->{fanPackState},
                                    $instance));
        my $exit = $self->get_severity(section => 'fanpack', value => $result->{fanPackState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fanpack '%s' status is %s", 
                                            $instance, $result->{fanPackState}));
        }
        
        if (defined($result->{fanPackAverageSpeedRPM}) && $result->{fanPackAverageSpeedRPM} =~ /[0-9]/) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fanpack', instance => $instance, value => $result->{fanPackAverageSpeedRPM});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Fanpack '%s' speed is %s rpm", $instance, $result->{fanPackAverageSpeedRPM}));
            }
            $self->{output}->perfdata_add(
                label => "fanpack", unit => 'rpm',
                nlabel => 'hardware.fanpack.speed.rpm',
                instances => $instance,
                value => $result->{fanPackAverageSpeedRPM},
                warning => $warn,
                critical => $crit,
                min => 0
            );
        }
    }
}

1;
