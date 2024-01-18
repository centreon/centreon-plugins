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

package network::stormshield::api::mode::components::temperature;

use strict;
use warnings;

sub load {}

sub check_temperature {
    my ($self, %options) = @_;

    return if ($self->check_filter(section => 'temperature', instance => $options{instance}));

    $self->{components}->{temperature}->{total}++;
    $self->{output}->output_add(
        long_msg => sprintf(
            "temperature '%s' is %s celsius [instance: %s]",
            $options{instance}, $options{value}, $options{instance}
        )
    );

    my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $options{instance}, value => $options{value});            
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "Temperature '%s' is %s celsius", $options{instance}, $options{value}
            )
        );
    }

    $self->{output}->perfdata_add(
        nlabel => 'hardware.temperature.celsius',
        unit => 'C',
        instances => $options{instance},
        value => $options{value},
        warning => $warn,
        critical => $crit
    );
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking temperatures');
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    check_temperature($self, instance => 'system', value => $self->{results}->{STAT_Result}->{temperature});
    my $num = 1;
    foreach (split(/,/, $self->{results}->{STAT_Result}->{CPUthermal})) {
        check_temperature($self, instance => 'cpu' . $num, value => $_);
        $num++;
    }
    foreach my $label (keys %{$self->{results}}) {
        if ($label =~ /POWERSUPPLY_POWER(\d+)/i && $self->{results}->{$label}->{powered} == 1) {
            check_temperature($self, instance => 'psu' . $1, value => sprintf('%.2f', $self->{results}->{$label}->{temperature}));
        }
        if ($label =~ /SMART_(\S+)$/i) {
            check_temperature($self, instance => 'disk_' . $1, value => $self->{results}->{$label}->{Temperature_Celsius});
        }
    }
}

1;
