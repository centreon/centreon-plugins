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

package apps::squid::snmp::mode::cacheusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } }
    ];
        
    $self->{maps_counters}->{global} = [
        { label => 'cpu', set => {
                key_values => [ { name => 'cacheCpuUsage' } ],
                output_template => 'Cpu usage : %s %%',
                perfdatas => [
                    { label => 'cpu', value => 'cacheCpuUsage', template => '%s',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'memory', set => {
                key_values => [ { name => 'cacheMemUsage' } ],
                output_template => 'Memory usage : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'memory', value => 'cacheMemUsage', template => '%s',
                      min => 0, unit => 'B' },
                ],
            }
        },
        { label => 'fd', set => {
                key_values => [ { name => 'cacheCurrentFileDescrCnt' } ],
                output_template => 'Number of file descriptors : %s',
                perfdatas => [
                    { label => 'fd', value => 'cacheCurrentFileDescrCnt', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'object', set => {
                key_values => [ { name => 'cacheNumObjCount' } ],
                output_template => 'Number of object stored : %s',
                perfdatas => [
                    { label => 'objects', value => 'cacheNumObjCount', template => '%s',
                      min => 0 },
                ],
            }
        },
    ];
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

sub manage_selection {
    my ($self, %options) = @_;

    my %oids = (
        cacheMemUsage => '.1.3.6.1.4.1.3495.1.3.1.3.0',
        cacheCpuUsage => '.1.3.6.1.4.1.3495.1.3.1.5.0',
        cacheNumObjCount => '.1.3.6.1.4.1.3495.1.3.1.7.0',
        cacheCurrentFileDescrCnt => '.1.3.6.1.4.1.3495.1.3.1.12.0',
    );
    my $snmp_result = $options{snmp}->get_leef(oids => [
            values %oids
        ], nothing_quit => 1);

    $snmp_result->{$oids{cacheMemUsage}} *= 1024;
    $self->{global} = {};
    foreach (keys %oids) {
        $self->{global}->{$_} = $snmp_result->{$oids{$_}} if (defined($snmp_result->{$oids{$_}}));
    }
}

1;

__END__

=head1 MODE

Check cache usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^(cpu)$'

=item B<--warning-*>

Threshold warning.
Can be: 'cpu', 'memory', 'fd', 'object'.

=item B<--critical-*>

Threshold critical.
Can be: 'cpu', 'memory', 'fd', 'object'.

=back

=cut
