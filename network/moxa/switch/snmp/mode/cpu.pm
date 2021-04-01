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

package network::moxa::switch::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 0, cb_prefix_output => 'prefix_cpu_output' }
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => '5s', set => {
                key_values => [ { name => 'cpuLoading5s' } ],
                output_template => '5 seconds : %.2f %%',
                perfdatas => [
                    { label => 'cpu_5s', value => 'cpuLoading5s', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => '30s', set => {
                key_values => [ { name => 'cpuLoading30s' } ],
                output_template => '30 seconds : %.2f %%',
                perfdatas => [
                    { label => 'cpu_30s', value => 'cpuLoading30s', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => '300s', set => {
                key_values => [ { name => 'cpuLoading300s' } ],
                output_template => '300 seconds : %.2f %%',
                perfdatas => [
                    { label => 'cpu_300s', value => 'cpuLoading300s', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU Usage ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

my $mappings = {
    iks6726a    => {
        cpuLoading5s        => { oid => '.1.3.6.1.4.1.8691.7.116.1.53' },
        cpuLoading30s       => { oid => '.1.3.6.1.4.1.8691.7.116.1.54' },
        cpuLoading300s      => { oid => '.1.3.6.1.4.1.8691.7.116.1.55' },
    },
    edsp506e => {
        cpuLoading5s        => { oid => '.1.3.6.1.4.1.8691.7.162.1.53' },
        cpuLoading30s       => { oid => '.1.3.6.1.4.1.8691.7.162.1.54' },
        cpuLoading300s      => { oid => '.1.3.6.1.4.1.8691.7.162.1.55' },
    },
    edsp506a => {
        cpuLoading5s        => { oid => '.1.3.6.1.4.1.8691.7.41.1.53' },
        cpuLoading30s       => { oid => '.1.3.6.1.4.1.8691.7.41.1.54' },
        cpuLoading300s      => { oid => '.1.3.6.1.4.1.8691.7.41.1.55' },
    },
};

my $oids = {
    iks6726a => '.1.3.6.1.4.1.8691.7.116.1',
    edsp506e => '.1.3.6.1.4.1.8691.7.162.1',
    edsp506a => '.1.3.6.1.4.1.8691.7.41.1',
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ { oid => $oids->{iks6726a}, start => $mappings->{iks6726a}->{cpuLoading5s}->{oid}, end => $mappings->{iks6726a}->{cpuLoading300s}->{oid} },
                                                                   { oid => $oids->{edsp506e}, start => $mappings->{edsp506e}->{cpuLoading5s}->{oid}, end => $mappings->{edsp506e}->{cpuLoading300s}->{oid} },
                                                                   { oid => $oids->{edsp506a}, start => $mappings->{edsp506a}->{cpuLoading5s}->{oid}, end => $mappings->{edsp506a}->{cpuLoading300s}->{oid} } ]);

    foreach my $equipment (keys %{$oids}) {
        next if (!%{$snmp_result->{$oids->{$equipment}}});
        my $result = $options{snmp}->map_instance(mapping => $mappings->{$equipment}, results => $snmp_result->{$oids->{$equipment}}, instance => 0);
        $self->{cpu} = { 
            cpuLoading5s => $result->{cpuLoading5s},
            cpuLoading30s => $result->{cpuLoading30s},
            cpuLoading300s => $result->{cpuLoading300s},
        };
    }
}

1;

__END__

=head1 MODE

Check CPU usage

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(30s|300s)$'

=item B<--warning-*>

Threshold warning.
Can be: '5s', '30s', '300s'

=item B<--critical-*>

Threshold critical.
Can be: '5s', '30s', '300s'

=back

=cut
