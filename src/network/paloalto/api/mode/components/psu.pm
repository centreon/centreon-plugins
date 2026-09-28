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

package network::paloalto::api::mode::components::psu;

use strict;
use warnings;
use centreon::plugins::misc qw/is_empty/;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = { name => 'power supplies', total => 0, skip => 0 };
    return if $self->check_filter(section => 'psu');

    foreach my $instance (sort keys %{$self->{data}->{psus}}) {
        my $result = $self->{data}->{psus}->{$instance};

        next if $self->check_filter(section => 'psu', instance => $instance);
        next if $self->check_filter(section => 'psu', instance => $result->{description});
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' alarm is '%s' [instance: %s, inserted: %s]",
                                    $result->{description}, $result->{alarm},
                                    $instance, $result->{inserted}));

        my $alarm_status = $self->get_severity(label => 'default', section => 'psu', value => $result->{alarm});
        $self->{output}->output_add(severity => $alarm_status, short_msg => sprintf("Power supply '%s' alarm is %s", $result->{description}, $alarm_status))
            unless $self->{output}->is_status(value => $alarm_status, compare => 'ok', litteral => 1);
    }
}

1;
