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

package network::citrix::netscaler::snmp::mode::cpu;
    
use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{name} . "' usage";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPUs are ok' }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'usage', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_usage' }, { name => 'name' } ],
                output_template => ': %.2f %%',
                perfdatas => [
                    { label => 'cpu', template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $mapping = {
    name       => { oid => '.1.3.6.1.4.1.5951.4.1.1.41.6.1.1' }, # nsCPUname
    cpu_usage  => { oid => '.1.3.6.1.4.1.5951.4.1.1.41.6.1.2' }  # nsCPUusage
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_nsCPUEntry = '.1.3.6.1.4.1.5951.4.1.1.41.6';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_nsCPUEntry, nothing_quit => 1);

    $self->{cpu} = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{name}->{oid}\.(.*)$/);

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
        $self->{cpu}->{ $result->{name} } = $result;
    }
}
    
1;

__END__

=head1 MODE

Check cpu usage (NS-MIB-smiv2).

=over 8

=item B<--warning-usage>

Threshold warning in percent.

=item B<--critical-usage>

Threshold critical in percent.

=back

=cut
    
