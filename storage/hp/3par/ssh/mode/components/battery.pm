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

package storage::hp::3par::ssh::mode::components::battery;

use strict;
use warnings;

sub load {
    my ($self) = @_;

#    Node PS Bat Assem_Serial   -State- ChrgLvl(%) -ExpDate- Expired Testing
#     0,1  0   0 6CQUBA1HN5065R OK             100 n/a       No      No     
#     0,1  1   0 6CQUBA1HN5063G OK             100 n/a       No      No     
#     2,3  0   0 6CQUBA1HN484RB OK             100 n/a       No      No     
#     2,3  1   0 6CQUBA1HN484R9 OK             100 n/a       No      No     
    push @{$self->{commands}}, 'echo "===showbattery==="', 'showbattery';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking batteries");
    $self->{components}->{battery} = { name => 'batteries', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'battery'));

    return if ($self->{results} !~ /===showbattery===.*?\n(.*?)(===|\Z)/msi);
    my @results = split /\n/, $1;

    foreach (@results) {
        next if (!/^\s*\S+\s+(\d+)\s+(\d+)\s+\S+\s+(\S+)\s+(\d+)/);
        my ($psu_id, $battery_id, $battery_state, $battery_chrg_lvl)  = ($1, $2, $3, $4);
        my $instance = $psu_id . '.' . $battery_id;
        
        next if ($self->check_filter(section => 'battery', instance => $instance));
        $self->{components}->{battery}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("battery '%s' on power supply '%s' status is '%s' [instance: %s, charge level: %d%%]",
                                    $psu_id, $battery_id, $battery_state, $instance, $battery_chrg_lvl)
                                    );
        my $exit = $self->get_severity(label => 'default', section => 'battery', value => $battery_state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Battery '%s' on power supply '%s' status is '%s'",
                                                             $psu_id, $battery_id, $battery_state, $instance));
        }

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'battery.charge', instance => $instance, value => $battery_chrg_lvl);

        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Battery '%s' on power supply '%s' charge level is %s %%",  $psu_id, $battery_id, $battery_chrg_lvl));
        }
        $self->{output}->perfdata_add(
            label => 'battery_charge', unit => '%',
            nlabel => 'hardware.battery.charge.percentage',
            instances => ['psu' . $psu_id, 'battery' . $battery_id],
            value => $battery_chrg_lvl,
            warning => $warn,
            critical => $crit,
            min => 0, max => 100,
        );
    }
}

1;
