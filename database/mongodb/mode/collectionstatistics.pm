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

package database::mongodb::mode::collectionstatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'databases', type => 3, cb_long_output => 'long_output',
          message_multiple => 'All databases statistics are ok', indent_long_output => '    ',
            group => [
                { name => 'collections', display_long => 1, cb_prefix_output => 'prefix_output_collection',
                  message_multiple => 'All collections statistics are ok', type => 1 },
            ]
        }
    ];

    $self->{maps_counters}->{collections} = [
        { label => 'storage-size', nlabel => 'collection.size.storage.bytes', set => {
                key_values => [ { name => 'storageSize' }, { name => 'display' } ],
                output_template => 'Storage Size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'storageSize', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'index-size', nlabel => 'collection.size.index.bytes', set => {
                key_values => [ { name => 'totalIndexSize' }, { name => 'display' } ],
                output_template => 'Index Size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'totalIndexSize', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'documents', nlabel => 'collection.documents.count', set => {
                key_values => [ { name => 'count' }, { name => 'display' } ],
                output_template => 'Documents: %s',
                perfdatas => [
                    { value => 'count', template => '%s',
                      min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'indexes', nlabel => 'collection.indexes.count', set => {
                key_values => [ { name => 'nindexes' }, { name => 'display' } ],
                output_template => 'Indexes: %s',
                perfdatas => [
                    { value => 'nindexes', template => '%s',
                      min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking database '" . $options{instance_value}->{display} . "' ";
}

sub prefix_output_collection {
    my ($self, %options) = @_;

    return "Collection '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-database:s"   => { name => 'filter_database' },
    });
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $databases = $options{custom}->list_databases();

    $self->{databases} = {};
    foreach my $database (sort @{$databases}) {
        next if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' 
            && $database !~ /$self->{option_results}->{filter_database}/);

        my $collections = $options{custom}->list_collections(database => $database);

        $self->{databases}->{$database}->{display} = $database;

        foreach my $collection (sort @{$collections}) {
            my $cl_stats = $options{custom}->run_command(
                database => $database,
                command => $options{custom}->ordered_hash(collStats => $collection),
            );
            
            $self->{databases}->{$database}->{collections}->{$collection} = {
                display => $collection,
                storageSize => $cl_stats->{storageSize},
                totalIndexSize => $cl_stats->{totalIndexSize},
                count => $cl_stats->{count},
                nindexes => $cl_stats->{nindexes},
            };
        }
    }

    if (scalar(keys %{$self->{databases}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No databases found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check collections statistics per databases

=over 8

=item B<--filter-database>

Filter database name (Can use regexp).

=item B<--warning-subinstance-collection-size-*-bytes>

Threshold warning.
Can be: 'storage', 'index'.

=item B<--critical-subinstance-collection-size-*-bytes>

Threshold critical.
Can be: 'storage', 'index'.

=item B<--warning-subinstance-collection-*-count>

Threshold warning.
Can be: 'documents', 'indexes'.

=item B<--critical-subinstance-collection-*-count>

Threshold critical.
Can be: 'documents', 'indexes'.

=back

=cut
