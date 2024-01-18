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

package apps::pfsense::snmp::mode::statetable;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return 'Number of state table ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'entries', nlabel => 'state_table.entries.count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'entries: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'searches', nlabel => 'state_table.search.count', set => {
                key_values => [ { name => 'searches', diff => 1 } ],
                output_template => 'searches: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'entries-inserted', nlabel => 'state_table.entries.inserted.count', set => {
                key_values => [ { name => 'inserted', diff => 1 } ],
                output_template => 'entries inserted: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'entries-removed', nlabel => 'state_table.entries.removed.count', set => {
                key_values => [ { name => 'removed', diff => 1 } ],
                output_template => 'entries removed: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Can't check SNMP 64 bits counters with SNMPv1.");
        $self->{output}->option_exit();
    }
    my $mapping = {
        count    => { oid => '.1.3.6.1.4.1.12325.1.200.1.3.1' }, # pfStateTableCount
        searches => { oid => '.1.3.6.1.4.1.12325.1.200.1.3.2' }, # pfStateTableSearches
        inserted => { oid => '.1.3.6.1.4.1.12325.1.200.1.3.3' }, # pfStateTableInserts
        removed  => { oid => '.1.3.6.1.4.1.12325.1.200.1.3.4' }  # pfStateTableRemovals
    };
    my $snmp_result = $options{snmp}->get_leef(oids => [ map($_->{oid} . '.0', values(%$mapping)) ], nothing_quit => 1);

    $self->{global} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

    $self->{cache_name} = 'pfsense_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check state table.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='count'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'entries', 'searches', 'entries-inserted', 'entries-removed'.

=back

=cut
