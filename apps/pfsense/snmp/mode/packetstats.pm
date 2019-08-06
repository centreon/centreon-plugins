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

package apps::pfsense::snmp::mode::packetstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'match', set => {
                key_values => [ { name => 'pfCounterMatch', diff => 1 } ],
                per_second => 1,
                output_template => 'Packets Matched Filter Rule : %.2f/s',
                perfdatas => [
                    { label => 'match', value => 'pfCounterMatch_per_second', template => '%.2f', unit => '/s',
                      min => 0 },
                ],
            }
        },
        { label => 'badoffset', set => {
                key_values => [ { name => 'pfCounterBadOffset', diff => 1 } ],
                per_second => 1,
                output_template => 'Bad Offset Packets : %.2f/s',
                perfdatas => [
                    { label => 'bad_offset', value => 'pfCounterBadOffset_per_second', template => '%.2f', unit => '/s',
                      min => 0 },
                ],
            }
        },
        { label => 'fragment', set => {
                key_values => [ { name => 'pfCounterFragment', diff => 1 } ],
                per_second => 1,
                output_template => 'Fragmented Packets : %.2f/s',
                perfdatas => [
                    { label => 'fragment', value => 'pfCounterFragment_per_second', template => '%.2f', unit => '/s',
                      min => 0 },
                ],
            }
        },
        { label => 'short', set => {
                key_values => [ { name => 'pfCounterShort', diff => 1 } ],
                per_second => 1,
                output_template => 'Short Packets : %.2f/s',
                perfdatas => [
                    { label => 'short', value => 'pfCounterShort_per_second', template => '%.2f', unit => '/s',
                      min => 0 },
                ],
            }
        },
        { label => 'normalize', set => {
                key_values => [ { name => 'pfCounterNormalize', diff => 1 } ],
                per_second => 1,
                output_template => 'Normalized Packets : %.2f/s',
                perfdatas => [
                    { label => 'normalize', value => 'pfCounterNormalize_per_second', template => '%.2f', unit => '/s',
                      min => 0 },
                ],
            }
        },
        { label => 'memdrop', set => {
                key_values => [ { name => 'pfCounterMemDrop', diff => 1 } ],
                per_second => 1,
                output_template => 'Dropped Packets Due To Memory : %.2f/s',
                perfdatas => [
                    { label => 'memdrop', value => 'pfCounterMemDrop_per_second', template => '%.2f', unit => '/s',
                      min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
                    
    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Can't check SNMP 64 bits counters with SNMPv1.");
        $self->{output}->option_exit();
    }
    my %oids = (
        pfCounterMatch      => '.1.3.6.1.4.1.12325.1.200.1.2.1.0',
        pfCounterBadOffset  => '.1.3.6.1.4.1.12325.1.200.1.2.2.0',
        pfCounterFragment   => '.1.3.6.1.4.1.12325.1.200.1.2.3.0',
        pfCounterShort      => '.1.3.6.1.4.1.12325.1.200.1.2.4.0',
        pfCounterNormalize  => '.1.3.6.1.4.1.12325.1.200.1.2.5.0',
        pfCounterMemDrop    => '.1.3.6.1.4.1.12325.1.200.1.2.6.0',
    );
    my $snmp_result = $options{snmp}->get_leef(oids => [values %oids], nothing_quit => 1);
    $self->{global} = {};
    foreach (keys %oids) {
        $self->{global}->{$_} = $snmp_result->{$oids{$_}};
    }

    $self->{cache_name} = "pfsense_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check global packet statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^match$'

=item B<--warning-*>

Threshold warning.
Can be: 'match', 'badoffset', 'fragment', 'short',
'normalize', 'memdrop'.

=item B<--critical-*>

Threshold critical.
Can be: 'match', 'badoffset', 'fragment', 'short',
'normalize', 'memdrop'.

=back

=cut
