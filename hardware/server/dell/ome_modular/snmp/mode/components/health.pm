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

package hardware::server::dell::ome_modular::snmp::mode::components::health;

use strict;
use warnings;

my %map_health_status = (
    1 => 'other',
    2 => 'unknown',
    3 => 'ok',
    4 => 'nonCritical',
    5 => 'critical',
    6 => 'nonRecoverable',
);

# In MIB 'MX7000-OME-M-v2'
my $mapping = {
    dmmIOMCurrStatus   => { oid => '.1.3.6.1.4.1.674.10892.6.3.1.1', map => \%map_health_status, descr => 'IOM status' },
    dmmRedCurrStatus   => { oid => '.1.3.6.1.4.1.674.10892.6.3.1.2', map => \%map_health_status, descr => 'Redundancy status' },
    dmmPowerCurrStatus => { oid => '.1.3.6.1.4.1.674.10892.6.3.1.3', map => \%map_health_status, descr => 'Power status' },
    dmmFanCurrStatus   => { oid => '.1.3.6.1.4.1.674.10892.6.3.1.4', map => \%map_health_status, descr => 'Fan status' },
    dmmBladeCurrStatus => { oid => '.1.3.6.1.4.1.674.10892.6.3.1.5', map => \%map_health_status, descr => 'Blade status' },
    dmmTempCurrStatus  => { oid => '.1.3.6.1.4.1.674.10892.6.3.1.6', map => \%map_health_status, descr => 'Temperature status' },
    dmmMMCurrStatus    => { oid => '.1.3.6.1.4.1.674.10892.6.3.1.7', map => \%map_health_status, descr => 'Management Module status' },
};
my $oid_dmmStatusNowGroup = '.1.3.6.1.4.1.674.10892.6.3.1';

sub load {
    my ($self) = @_;
    push @{$self->{request}}, {oid => $oid_dmmStatusNowGroup, start => $mapping->{dmmIOMCurrStatus}->{oid}, end => $mapping->{dmmMMCurrStatus}->{oid}};
}

sub check {
    my ($self) = @_;
    $self->{output}->output_add(long_msg => "Checking health");
    $self->{components}->{health} = {name => 'health', total => 0, skip => 0};
    return if ($self->check_filter(section => 'health'));
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_dmmStatusNowGroup}, instance => '0');
    foreach my $probe (keys %{$mapping}) {
        next if (!defined($result->{$probe}));

        $mapping->{$probe}->{oid} =~ /\.(\d+)$/;
        my $instance = $1;

        next if ( $self->check_filter(section => 'health', instance => $instance));
        $self->{components}->{health}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf("%s is %s [instance: %s].",
                            $mapping->{$probe}->{descr},
                            $result->{$probe},
                            $instance
            )
        );
        my $exit = $self->get_severity(section => 'health', value => $result->{$probe} ;
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("%s is %s",
                    $mapping->{$probe}->{descr},
                    $result->{$probe}
                )
            );
        }
    }
}

1;
