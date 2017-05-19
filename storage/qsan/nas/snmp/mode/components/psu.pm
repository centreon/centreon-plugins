#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package storage::qsan::nas::snmp::mode::components::psu;

use strict;
use warnings;

my $mapping = {
    ems_type    => { oid => '.1.3.6.1.4.1.22274.2.3.2.1.2' },
    ems_item    => { oid => '.1.3.6.1.4.1.22274.2.3.2.1.3' },
    ems_value   => { oid => '.1.3.6.1.4.1.22274.2.3.2.1.4' },
    ems_status  => { oid => '.1.3.6.1.4.1.22274.2.3.2.1.5' },
};
my $oid_monitorEntry = '.1.3.6.1.4.1.22274.2.3.2.1';

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_monitorEntry}})) {
        next if ($oid !~ /^$mapping->{ems_type}->{oid}\.(.*)$/);
        my $instance = $1;
        next if ($self->{results}->{$oid_monitorEntry}->{$oid} !~ /Power Supply/i);

        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_monitorEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'psu', instance => $instance));
        
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("power supply '%s' status is '%s' [instance = %s, value = %s]",
                                                        $result->{ems_item}, $result->{ems_status}, $instance, $result->{ems_value}));
        $exit = $self->get_severity(label => 'monitor', section => 'psu', value => $result->{ems_status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("power supply '%s' status is '%s'", $result->{ems_item}, $result->{ems_status}));
        }
    }
}

1;