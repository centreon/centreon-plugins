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

package database::mongodb::mode::databasestatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'databases', type => 1, cb_prefix_output => 'prefix_database_output',
          message_multiple => 'All databases statistics are ok' },
    ];

    $self->{maps_counters}->{databases} = [
        { label => 'storage-size', nlabel => 'database.size.storage.bytes', set => {
                key_values => [ { name => 'storageSize' }, { name => 'display' } ],
                output_template => 'Storage Size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'storageSize_absolute', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'data-size', nlabel => 'database.size.data.bytes', set => {
                key_values => [ { name => 'dataSize' }, { name => 'display' } ],
                output_template => 'Data Size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'dataSize_absolute', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'index-size', nlabel => 'database.size.index.bytes', set => {
                key_values => [ { name => 'indexSize' }, { name => 'display' } ],
                output_template => 'Index Size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'indexSize_absolute', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'collections', nlabel => 'database.collections.count', set => {
                key_values => [ { name => 'collections' }, { name => 'display' } ],
                output_template => 'Collections: %s',
                perfdatas => [
                    { value => 'collections_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'views', nlabel => 'database.views.count', set => {
                key_values => [ { name => 'views' }, { name => 'display' } ],
                output_template => 'Views: %s',
                perfdatas => [
                    { value => 'views_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'documents', nlabel => 'database.documents.count', set => {
                key_values => [ { name => 'documents' }, { name => 'display' } ],
                output_template => 'Documents: %s',
                perfdatas => [
                    { value => 'documents_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'indexes', nlabel => 'database.indexes.count', set => {
                key_values => [ { name => 'indexes' }, { name => 'display' } ],
                output_template => 'Indexes: %s',
                perfdatas => [
                    { value => 'indexes_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_database_output {
    my ($self, %options) = @_;

    return "Database '" . $options{instance_value}->{display} . "' ";
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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{custom} = $options{custom};

    $self->{databases} = {};
    
    my $databases = $self->{custom}->list_databases();

    foreach my $database (sort @{$databases}) {
        next if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' 
            && $database !~ /$self->{option_results}->{filter_database}/);

        my $db_stats = $self->{custom}->run_command(
            database => $database,
            command => $self->{custom}->ordered_hash('dbStats' => 1),
        );
        
        $self->{databases}->{$db_stats->{db}} = {
            display => $db_stats->{db},
            collections => $db_stats->{collections},
            views => $db_stats->{views},
            documents => $db_stats->{objects},
            storageSize => $db_stats->{storageSize},
            indexSize => $db_stats->{indexSize},
            dataSize => $db_stats->{dataSize},
            indexes => $db_stats->{indexes},
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

Filter database name (Can use regexp).

=item B<--warning-instance-database-size-*-bytes>

Threshold warning.
Can be: 'storage', 'data', 'index'.

=item B<--critical-instance-database-size-*-bytes>

Threshold critical.
Can be: 'storage', 'data', 'index'.

=item B<--warning-instance-database-*-count>

Threshold warning.
Can be: 'collections', 'views', 'documents',
'indexes'.

=item B<--critical-instance-database-*-count>

Threshold critical.
Can be: 'collections', 'views', 'documents',
'indexes'.

=back

=cut
