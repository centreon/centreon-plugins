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

package database::mysql::mode::databasessize;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', cb_init => 'skip_global'  },
        { name => 'database', type => 3, cb_prefix_output => 'prefix_database_output',
          cb_long_output => 'database_long_output', indent_long_output => '    ',
          message_multiple => 'All databases are ok', 
            group => [
                { name => 'global_db', type => 0, skipped_code => { -10 => 1 } },
                { name => 'table', display_long => 0, cb_prefix_output => 'prefix_table_output',
                  message_multiple => 'All tables are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-usage', nlabel => 'databases.space.usage.bytes', set => {
                key_values => [ { name => 'used' } ],
                output_template => 'Used Space: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'used', template => '%s', unit => 'B', 
                      min => 0 },
                ],
            }
        },
        { label => 'total-free', nlabel => 'databases.space.free.bytes', set => {
                key_values => [ { name => 'free' } ],
                output_template => 'Free Space: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'free', template => '%s', unit => 'B', 
                      min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{global_db} = [
        { label => 'db-usage', nlabel => 'database.space.usage.bytes', set => {
                key_values => [ { name => 'used' } ],
                output_template => 'Used: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'used', template => '%s', unit => 'B', 
                      min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'db-free', nlabel => 'database.space.free.bytes', set => {
                key_values => [ { name => 'free' } ],
                output_template => 'Free: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'free', template => '%s', unit => 'B', 
                      min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{table} = [
        { label => 'table-usage', nlabel => 'table.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'display' } ],
                output_template => 'Used: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'used', template => '%s', unit => 'B', 
                      min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'table-free', nlabel => 'table.space.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'display' } ],
                output_template => 'Free: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'free', template => '%s', unit => 'B', 
                      min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'table-frag', nlabel => 'table.fragmentation.percentage', set => {
                key_values => [ { name => 'frag' }, { name => 'display' } ],
                output_template => 'Fragmentation: %.2f %%',
                perfdatas => [
                    { value => 'frag', template => '%.2f', unit => '%', 
                      min => 0, max => 100, label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub skip_global {
    my ($self, %options) = @_;

    scalar(keys %{$self->{database}}) > 1 ? return(0) : return(1);
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Databases Total ";
}

sub prefix_database_output {
    my ($self, %options) = @_;

    return "Database '" . $options{instance_value}->{display} . "' ";
}

sub database_long_output {
    my ($self, %options) = @_;

    return "Checking Database '" . $options{instance_value}->{display} . "'";
}

sub prefix_table_output {
    my ($self, %options) = @_;

    return "Table '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-database:s' => { name => 'filter_database' },
        'filter-table:s'    => { name => 'filter_table' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    if (!($options{sql}->is_version_minimum(version => '5'))) {
        $self->{output}->add_option_msg(short_msg => "MySQL version '" . $self->{sql}->{version} . "' is not supported.");
        $self->{output}->option_exit();
    }
    $options{sql}->query(
        query => q{show variables like 'innodb_file_per_table'}
    );
    my ($name, $value) = $options{sql}->fetchrow_array();
    my $innodb_per_table = 0;
    $innodb_per_table = 1 if ($value =~ /on/i);

    $options{sql}->query(
        query => q{SELECT table_schema, table_name, engine, data_free, data_length+index_length as data_used, (DATA_FREE / (DATA_LENGTH+INDEX_LENGTH)) as TAUX_FRAG FROM information_schema.tables WHERE table_type = 'BASE TABLE' AND engine IN ('InnoDB', 'MyISAM')}
    );
    my $result = $options{sql}->fetchall_arrayref();

    my $innodb_ibdata_done = 0;
    $self->{global} = { free => 0, used => 0 };
    $self->{database} = {};
    foreach my $row (@$result) {
        if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' && 
            $row->[0] !~ /$self->{option_results}->{filter_database}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $row->[0] . '.' . $row->[1] . "': no matching filter.", debug => 1);
            next
        }
        if (defined($self->{option_results}->{filter_table}) && $self->{option_results}->{filter_table} ne '' &&
            $row->[1] !~ /$self->{option_results}->{filter_table}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $row->[0] . '.' . $row->[1] . "': no matching filter.", debug => 1);
            next
        }
        
        if (!defined($self->{database}->{$row->[0]})) {
            $self->{database}->{$row->[0]} = {
                display => $row->[0],
                global_db => { free => 0, used => 0 },
                table => {}
            };
        }

        $self->{database}->{$row->[0]}->{table}->{$row->[1]} = {
            display => $row->[1]
        };

        # For a table located in the shared tablespace, this is the free space of the shared tablespace.
        if ($row->[2] !~ /innodb/i || $innodb_per_table == 1) {
            $self->{global}->{free} += $row->[3];
            $self->{database}->{$row->[0]}->{global_db}->{free} += $row->[3];
            $self->{database}->{$row->[0]}->{table}->{$row->[1]}->{free} = $row->[3];
            $self->{database}->{$row->[0]}->{table}->{$row->[1]}->{frag} = $row->[5];
        } elsif ($innodb_ibdata_done == 0) {
            $self->{global}->{free} += $row->[3];
            $innodb_ibdata_done = 1;
        }
        $self->{global}->{used} += $row->[4];
        $self->{database}->{$row->[0]}->{global_db}->{used} += $row->[4];
        $self->{database}->{$row->[0]}->{table}->{$row->[1]}->{used} = $row->[4];
    }

    if (scalar(keys %{$self->{database}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No database found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check MySQL databases size and tables.

=over 8

=item B<--filter-database>

Filter database to checks (Can be a regexp).

=item B<--filter-table>

Filter table name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds (Can be: 'total-usage', 'total-free', 'db-usage',
'db-free', 'table-usage', 'table-free', 'table-frag').

=back

=cut
