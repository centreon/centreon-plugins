#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package hardware::server::dell::cmc::snmp::mode::components::health;

use strict;
use warnings;
use hardware::server::dell::cmc::snmp::mode::components::resources qw($map_status);

# In MIB 'DELL-RAC-MIB'
my $mapping = {
    drsIOMCurrStatus => { oid => '.1.3.6.1.4.1.674.10892.2.3.1.2', map => $map_status, descr => 'IOM status' },
    drsKVMCurrStatus => { oid => '.1.3.6.1.4.1.674.10892.2.3.1.3', map => $map_status, descr => 'iKVM status' },
    drsRedCurrStatus => { oid => '.1.3.6.1.4.1.674.10892.2.3.1.4', map => $map_status, descr => 'Redundancy status' },
    drsPowerCurrStatus => { oid => '.1.3.6.1.4.1.674.10892.2.3.1.5', map => $map_status, descr => 'Power status' },
    drsFanCurrStatus => { oid => '.1.3.6.1.4.1.674.10892.2.3.1.6', map => $map_status, descr => 'Fan status' },
    drsBladeCurrStatus => { oid => '.1.3.6.1.4.1.674.10892.2.3.1.7', map => $map_status, descr => 'Blade status' },
    drsTempCurrStatus => { oid => '.1.3.6.1.4.1.674.10892.2.3.1.8', map => $map_status, descr => 'Temperature status' },
    drsCMCCurrStatus => { oid => '.1.3.6.1.4.1.674.10892.2.3.1.9', map => $map_status, descr => 'CMC status' }
};
my $oid_drsStatusNowGroup = '.1.3.6.1.4.1.674.10892.2.3.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_drsStatusNowGroup, start => $mapping->{drsIOMCurrStatus}->{oid}, end => $mapping->{drsCMCCurrStatus}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking health");
    $self->{components}->{health} = {name => 'health', total => 0, skip => 0};
    return if ($self->check_filter(section => 'health'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_drsStatusNowGroup}, instance => 0);
    foreach my $probe (keys %{$mapping}) {
        next if (!defined($result->{$probe}));
        $mapping->{$probe}->{oid} =~ /\.(\d+)$/;
        my $instance = $1;

        next if ($self->check_filter(section => 'health', instance => $instance));
        $self->{components}->{health}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "%s is %s [instance: %s].",
                $mapping->{$probe}->{descr},
                $result->{$probe},
                $instance
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'health', value => $result->{$probe});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "%s is %s",
                    $mapping->{$probe}->{descr},
                    $result->{$probe}
                )
            );
        }
    }
}

1;
