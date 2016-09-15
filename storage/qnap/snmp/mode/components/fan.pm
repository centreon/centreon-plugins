#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package storage::qnap::snmp::mode::components::fan;

use strict;
use warnings;

# In MIB 'NAS.mib'
my $oid_SysFanDescr = '.1.3.6.1.4.1.24681.1.2.15.1.2';
my $oid_SysFanSpeed = '.1.3.6.1.4.1.24681.1.2.15.1.3';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_SysFanDescr };
    push @{$options{request}}, { oid => $oid_SysFanSpeed };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fan'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_SysFanDescr}})) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;
        my $fan_descr = $self->{results}->{$oid_SysFanDescr}->{$oid};
        my $fan_speed = defined($self->{results}->{$oid_SysFanSpeed}->{$oid_SysFanSpeed . '.' . $instance}) ? 
                            $self->{results}->{$oid_SysFanSpeed}->{$oid_SysFanSpeed . '.' . $instance} : 'unknown';

        next if ($self->check_exclude(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' [instance: %s] speed is '%s'.",
                                    $fan_descr, $instance, $fan_speed));

        if ($fan_speed =~ /([0-9]+)\s*rpm/i) {
            my $fan_speed_value = $1;
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $fan_speed_value);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Fan '%s' speed is %s rpm", $fan_descr, $fan_speed_value));
            }
            $self->{output}->perfdata_add(label => 'fan_' . $instance, unit => 'rpm',
                                          value => $fan_speed_value, min => 0
                                          );
        }
    }
}

1;