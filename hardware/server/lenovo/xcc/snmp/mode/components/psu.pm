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

package hardware::server::lenovo::xcc::snmp::mode::components::psu;

use strict;
use warnings;
use centreon::plugins::misc;

my $mapping = {
    powerFruName            => { oid => '.1.3.6.1.4.1.19046.11.1.1.11.2.1.2' },
    powerHealthStatus       => { oid => '.1.3.6.1.4.1.19046.11.1.1.11.2.1.6' },
};
my $oid_powerEntry = '.1.3.6.1.4.1.19046.11.1.1.11.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_powerEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_powerEntry}})) {
        next if ($oid !~ /^$mapping->{powerFruName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_powerEntry}, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance));
        $result->{powerFruName} = centreon::plugins::misc::trim($result->{powerFruName});
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("power supply '%s' status is %s [instance: %s].",
                                    $result->{powerFruName}, $result->{powerHealthStatus}, $instance));
        
        my $exit = $self->get_severity(label => 'default', section => 'psu', value => $result->{powerHealthStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' status is '%s'", $result->{powerFruName}, $result->{powerHealthStatus}));
        }
    }
}

1;
