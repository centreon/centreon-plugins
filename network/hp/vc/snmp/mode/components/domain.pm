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

package network::hp::vc::snmp::mode::components::domain;

use strict;
use warnings;
use network::hp::vc::snmp::mode::components::resources qw($map_managed_status $map_reason_code);

my $mapping = {
    vcDomainName => { oid => '.1.3.6.1.4.1.11.5.7.5.2.1.1.1.1' },
    vcDomainManagedStatus => { oid => '.1.3.6.1.4.1.11.5.7.5.2.1.1.1.2', map => $map_managed_status },
    vcDomainReasonCode => { oid => '.1.3.6.1.4.1.11.5.7.5.2.1.1.1.10', map => $map_reason_code },
};
my $oid_vcDomain = '.1.3.6.1.4.1.11.5.7.5.2.1.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_vcDomain };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking domains");
    $self->{components}->{domain} = { name => 'domains', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'domain'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_vcDomain}})) {
        next if ($oid !~ /^$mapping->{vcDomainManagedStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_vcDomain}, instance => $instance);

        next if ($self->check_filter(section => 'domain', instance => $instance));
        $self->{components}->{domain}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("domain '%s' status is '%s' [instance: %s, reason: %s].",
                                    $result->{vcDomainName}, $result->{vcDomainManagedStatus},
                                    $instance, $result->{vcDomainReasonCode}
                                    ));
        my $exit = $self->get_severity(section => 'domain', label => 'default', value => $result->{vcDomainManagedStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Domain '%s' status is '%s'",
                                                             $result->{vcDomainName}, $result->{vcDomainManagedStatus}));
        }
    }
}

1;