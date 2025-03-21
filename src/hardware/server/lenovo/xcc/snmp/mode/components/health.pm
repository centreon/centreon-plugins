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

package hardware::server::lenovo::xcc::snmp::mode::components::health;
        use Data::Dumper;

use strict;
use warnings;
use centreon::plugins::misc;

my $mapping = {
    healthStatus       => { oid => '.1.3.6.1.4.1.19046.11.1.1.4.2.1.2' },
    healthString       => { oid => '.1.3.6.1.4.1.19046.11.1.1.4.2.1.3' },
};

my $oid_healthEntry = '.1.3.6.1.4.1.19046.11.1.1.4.2.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_healthEntry };
}
sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking health");
    $self->{components}->{health} = { name => 'health', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'health'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_healthEntry}})) {

        next if ($oid !~ /^$mapping->{healthString}->{oid}\.(.*)$/);

        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_healthEntry}, instance => $instance);
        next if ($self->check_filter(section => 'health', instance => $instance));
        $result->{healthStatus} = centreon::plugins::misc::trim($result->{healthStatus});
        $self->{components}->{health}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("health '%s' status is %s [instance: %s].",
                                    $result->{healthString}, $result->{healthStatus}, $instance));
        
        my $exit = $self->get_severity(label => 'default', section => 'default', value => $result->{healthStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("'%s' health status for '%s'", $result->{healthStatus}, $result->{healthString}));
        }
    }
}

1;