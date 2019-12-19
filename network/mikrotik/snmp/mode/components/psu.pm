#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::mikrotik::snmp::mode::components::psu;

use strict;
use warnings;

my $map_status = { 0 => 'false', 1 => 'true' };

my $mapping = {
    mtxrHlPower                  => { oid => '.1.3.6.1.4.1.14988.1.1.3.12' },
    mtxrHlPowerSupplyState       => { oid => '.1.3.6.1.4.1.14988.1.1.3.15', map => $map_status },
    mtxrHlBackupPowerSupplyState => { oid => '.1.3.6.1.4.1.14988.1.1.3.16', map => $map_status },
};

sub load {}

sub check_psu {
    my ($self, %options) = @_;
    
    return if (!defined($options{value}));
    
    $self->{output}->output_add(
        long_msg => sprintf(
            "psu %s status is '%s'",
            $options{type}, $options{value}, 
        )
    );

    my $exit = $self->get_severity(section => 'psu.' . $options{type}, value => $options{value});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("psu %s status is '%s'", $options{type}, $options{value}));
    }
    
    $self->{components}->{psu}->{total}++;
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));
    
    my $instance = '0';
    my ($exit, $warn, $crit, $checked);
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
    
    check_psu($self, value => $result->{mtxrHlPowerSupplyState}, type => 'primary');
    check_psu($self, value => $result->{mtxrHlBackupPowerSupplyState}, type => 'backup');
    
    if (defined($result->{mtxrHlPower}) && $result->{mtxrHlPower} =~ /[0-9]+/) {
        $self->{output}->output_add(long_msg => sprintf("Power is '%s' W", $result->{mtxrHlPower} / 10));

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'psu', instance => $instance, value => $result->{mtxrHlPower} / 10);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power is '%s' W", $result->{mtxrHlPower} / 10));
        }
        $self->{output}->perfdata_add(
            label => 'power', unit => 'W',
            nlabel => 'hardware.power.watt',
            value => $result->{mtxrHlPower} / 10,
            warning => $warn,
            critical => $crit
        );
        $self->{components}->{psu}->{total}++;
    }
}

1;
