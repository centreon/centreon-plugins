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

package hardware::sensors::akcp::snmp::mode::components::securityport;

use strict;
use warnings;
use hardware::sensors::akcp::snmp::mode::components::resources qw(%map_default2_status);

my $mapping = {
    securityPortDescription  => { oid => '.1.3.6.1.4.1.3854.3.5.10.1.2' },
    securityPortStatus       => { oid => '.1.3.6.1.4.1.3854.3.5.10.1.6', map => \%map_default2_status },
};
my $oid_securityPortEntry = '.1.3.6.1.4.1.3854.3.5.10.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_securityPortEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking security ports");
    $self->{components}->{securityport} = {name => 'security ports', total => 0, skip => 0};
    return if ($self->check_filter(section => 'securityport'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_securityPortEntry}})) {
        next if ($oid !~ /^$mapping->{securityPortStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_securityPortEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'securityport', instance => $instance));
        $self->{components}->{securityport}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("security port '%s' status is '%s' [instance = %s]",
                                    $result->{securityPortDescription}, $result->{securityPortStatus}, $instance,
                                    ));
        
        my $exit = $self->get_severity(label => 'default2', section => 'securityport', value => $result->{securityPortStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Security port '%s' status is '%s'", $result->{securityPortDescription}, $result->{securityPortStatus}));
        }
    }
}

1;
