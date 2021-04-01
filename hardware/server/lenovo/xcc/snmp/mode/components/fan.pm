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

package hardware::server::lenovo::xcc::snmp::mode::components::fan;

use strict;
use warnings;
use centreon::plugins::misc;

my $mapping = {
    fanDescr        => { oid => '.1.3.6.1.4.1.19046.11.1.1.3.2.1.2' },
    fanSpeed        => { oid => '.1.3.6.1.4.1.19046.11.1.1.3.2.1.3' },
    fanHealthStatus => { oid => '.1.3.6.1.4.1.19046.11.1.1.3.2.1.10' },
};
my $oid_fanEntry = '.1.3.6.1.4.1.19046.11.1.1.3.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_fanEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fanEntry}})) {
        next if ($oid !~ /^$mapping->{fanSpeed}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fanEntry}, instance => $instance);
        $result->{fanDescr} = centreon::plugins::misc::trim($result->{fanDescr});
        $result->{fanSpeed} = centreon::plugins::misc::trim($result->{fanSpeed});
        
        next if ($self->check_filter(section => 'fan', instance => $instance));

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' status is '%s' [instance = %s][value: %s]",
                                                        $result->{fanDescr}, $result->{fanHealthStatus}, $instance, $result->{fanSpeed}));
        
        my $exit = $self->get_severity(label => 'default', section => 'fan', value => $result->{fanHealthStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' status is '%s'", $result->{fanDescr}, $result->{fanHealthStatus}));
        }
        
        next if ($result->{fanSpeed} !~ /(\d+)/);
        
        my $fan_speed = $1;
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $fan_speed);            
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Fan '%s' is '%s' %%", $result->{fanDescr}, $fan_speed));
        }
        $self->{output}->perfdata_add(
            label => 'fan', unit => '%',
            nlabel => 'hardware.fan.speed.percentage',
            instances => $result->{fanDescr},
            value => $fan_speed,
            warning => $warn,
            critical => $crit, min => 0, max => 100
        );
    }
}

1;
