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

package database::mongodb::mode::collectionstatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_shard_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => $self->{instance_mode}->{option_results}->{unit},
        instances => [$self->{result_values}->{dbName}, $self->{result_values}->{collectionName}, $self->{result_values}->{shardName}],
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub long_output {
    my ($self, %options) = @_;

    return "checking database '" . $options{instance_value}->{display} . "' ";
}

sub prefix_output_collection {
    my ($self, %options) = @_;

    return "collection '" . $options{instance} . "' ";
}

sub prefix_output_shard {
    my ($self, %options) = @_;

    return sprintf(
        "collection '%s' shard '%s' ",
        $options{instance_value}->{collectionName},
        $options{instance_value}->{shardName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'databases', type => 3, cb_long_output => 'long_output',
          message_multiple => 'All databases statistics are ok', indent_long_output => '    ',
            group => [
                { name => 'collections', display_long => 1, cb_prefix_output => 'prefix_output_collection',
                  message_multiple => 'All collections statistics are ok', type => 1 },
                { name => 'shards', display_long => 1, cb_prefix_output => 'prefix_output_shard',
                  message_multiple => 'All shards collections statistics are ok', type => 1 }
            ]
        }
    ];

    $self->{maps_counters}->{collections} = [
        { label => 'storage-size', nlabel => 'collection.size.storage.bytes', set => {
                key_values => [ { name => 'storageSize' } ],
                output_template => 'storage size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'index-size', nlabel => 'collection.size.index.bytes', set => {
                key_values => [ { name => 'totalIndexSize' } ],
                output_template => 'index size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'documents', nlabel => 'collection.documents.count', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'documents: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'indexes', nlabel => 'collection.indexes.count', set => {
                key_values => [ { name => 'nindexes' } ],
                output_template => 'indexes: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{shards} = [
        { label => 'shard-storage-size', nlabel => 'collection.size.storage.bytes', set => {
                key_values => [ { name => 'storageSize' }, { name => 'dbName' }, { name => 'collectionName' }, { name => 'shardName' } ],
                output_template => 'storage size: %s %s',
                output_change_bytes => 1,
                closure_custom_perfdata => $self->can('custom_shard_perfdata')
            }
        },
        { label => 'shard-index-size', nlabel => 'collection.size.index.bytes', set => {
                key_values => [ { name => 'totalIndexSize' }, { name => 'dbName' }, { name => 'collectionName' }, { name => 'shardName' } ],
                output_template => 'index size: %s %s',
                output_change_bytes => 1,
                closure_custom_perfdata => $self->can('custom_shard_perfdata')
            }
        },
        { label => 'shard-documents', nlabel => 'collection.documents.count', set => {
                key_values => [ { name => 'count' }, { name => 'dbName' }, { name => 'collectionName' }, { name => 'shardName' } ],
                output_template => 'documents: %s',
                closure_custom_perfdata => $self->can('custom_shard_perfdata')
            }
        },
        { label => 'shard-indexes', nlabel => 'collection.indexes.count', set => {
                key_values => [ { name => 'nindexes' }, { name => 'dbName' }, { name => 'collectionName' }, { name => 'shardName' } ],
                output_template => 'indexes: %s',
                closure_custom_perfdata => $self->can('custom_shard_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-database:s' => { name => 'filter_database' },
        'filter-shard:s'    => { name => 'filter_shard' },
        'add-shards'        => { name => 'add_shards' }
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

        $self->{databases}->{$database} = {
            display => $database,
            collections => {},
            shards => {}
        };

        foreach my $collection (sort @{$collections}) {
            my $cl_stats = $options{custom}->run_command(
                database => $database,
                command => $options{custom}->ordered_hash(collStats => $collection)
            );

            $self->{databases}->{$database}->{collections}->{$collection} = {
                storageSize => $cl_stats->{storageSize},
                totalIndexSize => $cl_stats->{totalIndexSize},
                count => $cl_stats->{count},
                nindexes => $cl_stats->{nindexes}
            };

            if (defined($self->{option_results}->{add_shards}) && defined($cl_stats->{shards})) {
                foreach my $shard_name (keys %{$cl_stats->{shards}}) {
                    next if (defined($self->{option_results}->{filter_shard}) && $self->{option_results}->{filter_shard} ne '' 
                        && $shard_name !~ /$self->{option_results}->{filter_shard}/);

                    $self->{databases}->{$database}->{shards}->{$collection . $shard_name} = {
                        dbName => $database,
                        collectionName => $collection,
                        shardName => $shard_name,
                        storageSize => $cl_stats->{shards}->{$shard_name}->{storageSize},
                        totalIndexSize => $cl_stats->{shards}->{$shard_name}->{totalIndexSize},
                        count => $cl_stats->{shards}->{$shard_name}->{count},
                        nindexes => $cl_stats->{shards}->{$shard_name}->{nindexes}
                    };
                }
            }
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

Filter databases by name (can use regexp).

=item B<--filter-shard>

Filter shards by name (can use regexp).

=item B<--add-shards>

Add collection statistics by shards.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'storage-size', 'index-size', 'documents', 'indexes',
'shard-storage-size', 'shard-index-size', 'shard-documents', 'shard-indexes'.

=back

=cut
