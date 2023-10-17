#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package database::mongodb::mode::databasestatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_shard_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => $self->{instance_mode}->{option_results}->{unit},
        instances => [$self->{result_values}->{dbName}, $self->{result_values}->{shardName}],
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub prefix_database_output {
    my ($self, %options) = @_;

    return "Database '" . $options{instance_value}->{display} . "' ";
}

sub prefix_shard_output {
    my ($self, %options) = @_;

    return sprintf(
        "Database '%s' shard '%s' ",
        $options{instance_value}->{dbName},
        $options{instance_value}->{shardName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'databases', type => 1, cb_prefix_output => 'prefix_database_output',
          message_multiple => 'All databases statistics are ok' },
        { name => 'shards', type => 1, cb_prefix_output => 'prefix_shard_output',
          message_multiple => 'All shards databases statistics are ok' }, 
    ];

    $self->{maps_counters}->{databases} = [
        { label => 'storage-size', nlabel => 'database.size.storage.bytes', set => {
                key_values => [ { name => 'storageSize' } ],
                output_template => 'storage size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'data-size', nlabel => 'database.size.data.bytes', set => {
                key_values => [ { name => 'dataSize' } ],
                output_template => 'data size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'index-size', nlabel => 'database.size.index.bytes', set => {
                key_values => [ { name => 'indexSize' } ],
                output_template => 'index size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'collections', nlabel => 'database.collections.count', set => {
                key_values => [ { name => 'collections' } ],
                output_template => 'collections: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'views', nlabel => 'database.views.count', set => {
                key_values => [ { name => 'views' } ],
                output_template => 'views: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'documents', nlabel => 'database.documents.count', set => {
                key_values => [ { name => 'documents' } ],
                output_template => 'documents: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'indexes', nlabel => 'database.indexes.count', set => {
                key_values => [ { name => 'indexes' } ],
                output_template => 'indexes: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{shards} = [
        { label => 'shard-storage-size', nlabel => 'database.size.storage.bytes', set => {
                key_values => [ { name => 'storageSize' }, { name => 'dbName' }, { name => 'shardName' } ],
                output_template => 'storage size: %s %s',
                output_change_bytes => 1,
                closure_custom_perfdata => $self->can('custom_shard_perfdata')
            }
        },
        { label => 'shard-data-size', nlabel => 'database.size.data.bytes', set => {
                key_values => [ { name => 'dataSize' }, { name => 'dbName' }, { name => 'shardName' } ],
                output_template => 'data size: %s %s',
                output_change_bytes => 1,
                closure_custom_perfdata => $self->can('custom_shard_perfdata')
            }
        },
        { label => 'shard-index-size', nlabel => 'database.size.index.bytes', set => {
                key_values => [ { name => 'indexSize' }, { name => 'dbName' }, { name => 'shardName' } ],
                output_template => 'index size: %s %s',
                output_change_bytes => 1,
                closure_custom_perfdata => $self->can('custom_shard_perfdata')
            }
        },
        { label => 'shard-collections', nlabel => 'database.collections.count', set => {
                key_values => [ { name => 'collections' }, { name => 'dbName' }, { name => 'shardName' } ],
                output_template => 'collections: %s',
                closure_custom_perfdata => $self->can('custom_shard_perfdata')
            }
        },
        { label => 'shard-views', nlabel => 'database.views.count', set => {
                key_values => [ { name => 'views' }, { name => 'dbName' }, { name => 'shardName' } ],
                output_template => 'views: %s',
                closure_custom_perfdata => $self->can('custom_shard_perfdata')
            }
        },
        { label => 'shard-documents', nlabel => 'database.documents.count', set => {
                key_values => [ { name => 'documents' }, { name => 'dbName' }, { name => 'shardName' } ],
                output_template => 'documents: %s',
                closure_custom_perfdata => $self->can('custom_shard_perfdata')
            }
        },
        { label => 'shard-indexes', nlabel => 'database.indexes.count', set => {
                key_values => [ { name => 'indexes' }, { name => 'dbName' }, { name => 'shardName' } ],
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

    $self->{shards} = {};
    $self->{databases} = {};
    foreach my $database (sort @{$databases}) {
        next if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' 
            && $database !~ /$self->{option_results}->{filter_database}/);

        my $db_stats = $options{custom}->run_command(
            database => $database,
            command => $options{custom}->ordered_hash(dbStats => 1)
        );

        $self->{databases}->{$database} = {
            display => $database,
            collections => $db_stats->{collections},
            views => $db_stats->{views},
            documents => $db_stats->{objects},
            storageSize => $db_stats->{storageSize},
            indexSize => $db_stats->{indexSize},
            dataSize => $db_stats->{dataSize},
            indexes => $db_stats->{indexes}
        };

        if (defined($self->{option_results}->{add_shards}) && defined($db_stats->{raw})) {
            foreach my $shard_name (keys %{$db_stats->{raw}}) {
                next if (defined($self->{option_results}->{filter_shard}) && $self->{option_results}->{filter_shard} ne '' 
                    && $shard_name !~ /$self->{option_results}->{filter_shard}/);

                $self->{shards}->{$database . $shard_name} = {
                    dbName => $database,
                    shardName => $shard_name,
                    collections => $db_stats->{raw}->{$shard_name}->{collections},
                    views => $db_stats->{raw}->{$shard_name}->{views},
                    documents => $db_stats->{raw}->{$shard_name}->{objects},
                    storageSize => $db_stats->{raw}->{$shard_name}->{storageSize},
                    indexSize => $db_stats->{raw}->{$shard_name}->{indexSize},
                    dataSize => $db_stats->{raw}->{$shard_name}->{dataSize},
                    indexes => $db_stats->{raw}->{$shard_name}->{indexes}
                };
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

Check databases statistics

=over 8

=item B<--filter-database>

Filter databases by name (Can use regexp).

=item B<--filter-shard>

Filter shards by name (Can use regexp).

=item B<--add-shards>

Add database statistics by shards.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'storage-size', 'data-size', 'index-size', 'collections', 'views', 'documents', 'indexes',
'shard-storage-size', 'shard-data-size', 'shard-index-size', 'shard-collections', 'shard-views', 'shard-documents', 'shard-indexes'.

=back

=cut
