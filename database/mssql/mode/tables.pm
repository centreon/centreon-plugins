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

package database::mssql::mode::tables;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_database_output {
    my ($self, %options) = @_;

    return "Database '" . $options{instance_value}->{display} . "' ";
}

sub database_long_output {
    my ($self, %options) = @_;

    return "checking database '" . $options{instance_value}->{display} . "'";
}

sub prefix_table_output {
    my ($self, %options) = @_;

    return "table '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'databases', type => 3, cb_prefix_output => 'prefix_database_output', cb_long_output => 'database_long_output', indent_long_output => '    ',
          message_multiple => 'All databases are ok', 
            group => [
                { name => 'global_db', type => 0, skipped_code => { -10 => 1 } },
                { name => 'tables', display_long => 0, cb_prefix_output => 'prefix_table_output',
                  message_multiple => 'all tables are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global_db} = [
        { label => 'db-usage', nlabel => 'database.space.usage.bytes', set => {
                key_values => [ { name => 'used' } ],
                output_template => 'used: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', unit => 'B', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'db-free', nlabel => 'database.space.free.bytes', set => {
                key_values => [ { name => 'free' } ],
                output_template => 'free: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', unit => 'B', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{tables} = [
        { label => 'table-usage', nlabel => 'table.space.usage.bytes', set => {
                key_values => [ { name => 'used' } ],
                output_template => 'used: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', unit => 'B', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'table-free', nlabel => 'table.space.free.bytes', set => {
                key_values => [ { name => 'free' } ],
                output_template => 'free: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', unit => 'B', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'table-rows', nlabel => 'table.rows.count', set => {
                key_values => [ { name => 'rows' } ],
                output_template => 'rows: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
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
        'filter-table:s'    => { name => 'filter_table' }
    });

    return $self;
}

sub add_tables {
    my ($self, %options) = @_;

    # page size is 8KB
    my $dbname = $options{dbname};
    $options{sql}->query(query => qq{
        USE [$dbname]
        SELECT
            s.Name AS SchemaName,
            t.Name AS TableName,
            p.rows AS RowCounts,
            (SUM(a.used_pages * 8)) AS Used_KB,
            (SUM(a.total_pages * 8) - SUM(a.used_pages * 8)) AS Unused_KB,
            (SUM(a.total_pages * 8)) AS Total_KB
        FROM sys.tables t
        INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
        INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
        INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
        GROUP BY t.Name, s.Name, p.Rows
    });
    my $results = $options{sql}->fetchall_arrayref();
    foreach my $row (@$results) {
        if (defined($self->{option_results}->{filter_table}) && $self->{option_results}->{filter_table} ne '' &&
            $row->[1] !~ /$self->{option_results}->{filter_table}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $row->[0] . '.' . $row->[1] . "': no matching filter.", debug => 1);
            next
        }

        $self->{databases}->{$dbname}->{tables}->{ $row->[1] } = {
            display => $row->[1],
            used => $row->[5] * 1024,
            free => $row->[4] * 1024,
            rows => $row->[2]
        };
        $self->{databases}->{$dbname}->{global_db}->{free} += $row->[4] * 1024;
        $self->{databases}->{$dbname}->{global_db}->{used} += $row->[5] * 1024;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => qq{
        SELECT [name] as database_name
        FROM sys.databases
    });

    $self->{databases} = {};
    my $results = $options{sql}->fetchall_arrayref();
    foreach my $row (@$results) {
        if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' && 
            $row->[0] !~ /$self->{option_results}->{filter_database}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $row->[0] . "': no matching filter.", debug => 1);
            next
        }

        $self->{databases}->{ $row->[0] } = {
            display => $row->[0],
            global_db => { free => 0, used => 0 },
            table => {}
        };

        $self->add_tables(dbname => $row->[0], sql => $options{sql});
    }

    if (scalar(keys %{$self->{databases}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No database found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check tables size.

=over 8

=item B<--filter-database>

Filter tables by database name (Can be a regexp).

=item B<--filter-table>

Filter tables by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'db-usage', 'db-free', 'table-usage', 'table-free', 'table-rows'.

=back

=cut
