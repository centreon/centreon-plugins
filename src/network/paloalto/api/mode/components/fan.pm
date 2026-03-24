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

package network::paloalto::api::mode::components::fan;

use strict;
use warnings;
use centreon::plugins::misc qw/is_empty/;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if $self->check_filter(section => 'fan');

    foreach my $instance (sort keys %{$self->{data}->{fans}}) {
        my $result = $self->{data}->{fans}->{$instance};

        next if $self->check_filter(section => 'fan', instance => $instance);
        next if $self->check_filter(section => 'fan', instance => $result->{description});
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Fan '%s' alarm is '%s' [instance: %s, rpm: %s]",
                                    $result->{description}, $result->{alarm},
                                    $instance, $result->{rpm}));

        my $alarm_status = $result->{alarm} =~ /true/i ? 'CRITICAL' : 'OK';
        $self->{output}->output_add(severity => $alarm_status, short_msg => sprintf("Fan '%s' alarm is %s", $result->{description}, $alarm_status))
	    unless $self->{output}->is_status(value => $alarm_status, compare => 'ok', litteral => 1);

        unless (is_empty($result->{rpm})){
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(
                section => 'fan',
                instance => $instance,
                value => $result->{rpm}
            );
            $self->{output}->output_add(severity => $exit, short_msg => sprintf("Fan '%s' rpm is %s", $result->{description}, $result->{rpm}))
		unless $self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1);

            my $label = $result->{description} . '#hardware.fan.speed.rpm';
            $self->{output}->perfdata_add(
                label => $label,
                unit => 'rpm',
                value => $result->{rpm},
                warning => $warn,
                critical => $crit,
                min => $result->{min}
            );
        }
    }
}

1;
