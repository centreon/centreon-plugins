#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::evertz::FC7800::snmp::mode::components::frameline;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_frameline_status = (1 => 'false', 2 => 'true', 3 => 'notAvailable');

my $mapping_frameline = {
    frameStatusLine => { oid => '.1.3.6.1.4.1.6827.10.232.4.2', map => \%map_frameline_status },
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, $mapping_frameline->{frameStatusLine}->{oid} . '.0';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking frame line");
    $self->{components}->{frameline} = {name => 'frameline', total => 0, skip => 0};
    return if ($self->check_filter(section => 'frameline'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping_frameline, results => $self->{results}, instance => '0');

    return if (!defined($result->{frameStatusLine}));
    $self->{components}->{frameline}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("frame line status is '%s' [instance = %s]",
                                                    $result->{frameStatusLine}, '0'));
    my $exit = $self->get_severity(section => 'frameline', value => $result->{frameStatusLine});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Frame line status is '%s'", $result->{frameStatusLine}));
    }
}

1;