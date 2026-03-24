#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::paloalto::api::mode::components::voltage;

use strict;
use warnings;
use centreon::plugins::misc qw/is_empty/;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = { name => 'voltages', total => 0, skip => 0 };
    return if $self->check_filter(section => 'voltage');

    foreach my $instance (sort keys %{$self->{data}->{voltages}}) {
        my $result = $self->{data}->{voltages}->{$instance};

        next if $self->check_filter(section => 'voltage', instance => $instance);
        next if $self->check_filter(section => 'voltage', instance => $result->{description});
        $self->{components}->{voltage}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Voltage '%s' alarm is '%s' [instance: %s, value: %s V]",
                                    $result->{description}, $result->{alarm},
                                    $instance, $result->{value}));

        my $alarm_status = $result->{alarm} =~ /true/i ? 'CRITICAL' : 'OK';
        $self->{output}->output_add(severity => $alarm_status, short_msg => sprintf("Voltage '%s' alarm is %s", $result->{description}, $alarm_status))
	    unless $self->{output}->is_status(value => $alarm_status, compare => 'ok', litteral => 1);

        unless (is_empty($result->{value})) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(
                section => 'voltage',
                instance => $instance,
                value => $result->{value}
            );
            $self->{output}->output_add(severity => $exit, short_msg => sprintf("Voltage '%s' value is %s V", $result->{description}, $result->{value}))
		unless $self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1);

            my $label = $result->{description} . '#hardware.voltage.volt';
            $self->{output}->perfdata_add(
                label => $label,
                unit => 'V',
                value => $result->{value},
                warning => $warn,
                critical => $crit,
                min => $result->{min},
                max => $result->{max}
            );
        }
    }
}

1;
