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

package database::postgres::mode::bloat;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_database_output {
    my ($self, %options) = @_;

    return "Database '" . $options{instance} . "' ";
}

sub database_long_output {
    my ($self, %options) = @_;

    return "checking database '" . $options{instance} . "'";
}

sub prefix_table_output {
    my ($self, %options) = @_;

    return "table '" . $options{instance} . "' ";
}

sub prefix_index_output {
    my ($self, %options) = @_;

    return "index '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'databases', type => 3, cb_prefix_output => 'prefix_database_output', cb_long_output => 'database_long_output', indent_long_output => '    ',
          message_multiple => 'All tables and indexes are ok', 
            group => [
                { name => 'tables', display_long => 1, cb_prefix_output => 'prefix_table_output',
                  message_multiple => 'all tables are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'indexes', display_long => 1, cb_prefix_output => 'prefix_index_output',
                  message_multiple => 'all indexes are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
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
        { label => 'table-dead-tuple', nlabel => 'table.dead_tuple.bytes', set => {
                key_values => [ { name => 'dead_tuple_len' } ],
                output_template => 'dead tuple: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', unit => 'B', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{indexes} = [
        { label => 'index-usage', nlabel => 'index.space.usage.bytes', set => {
                key_values => [ { name => 'used' } ],
                output_template => 'used: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', unit => 'B', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'index-leaf-density', nlabel => 'index.leaf_density.percentage', set => {
                key_values => [ { name => 'avg_leaf_density' } ],
                output_template => 'average leaf density: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
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
        'filter-table:s' => { name => 'filter_table' },
        'filter-index:s' => { name => 'filter_index' },
        'filter-size:s'  => { name => 'filter_size' }
    });

    return $self;
}

sub add_tables {
    my ($self, %options) = @_;

    $options{sql}->query(query => qq{
        SELECT current_database() as dbname, relname, (pgstattuple(oid)).* from pg_class where relkind IN ('r', 'm') AND relpersistence <> 't'
    });

    while (my $row = $options{sql}->fetchrow_hashref()) {
        $self->{databases}->{ $row->{dbname} } = { tables => {}, indexes => {} }
            if (!defined($self->{databases}->{ $row->{dbname} }));

        if (defined($self->{option_results}->{filter_table}) && $self->{option_results}->{filter_table} ne '' &&
            $row->{relname} !~ /$self->{option_results}->{filter_table}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $row->{relname} . "': no matching filter.", debug => 1);
            next
        }
        next if (defined($self->{option_results}->{filter_size}) && $self->{option_results}->{filter_size} =~ /^\d+$/ &&
            $row->{table_len} < $self->{option_results}->{filter_size});

        $self->{databases}->{ $row->{dbname} }->{tables}->{ $row->{relname} } = {
            used => $row->{table_len},
            free => $row->{free_space},
            dead_tuple_len => $row->{dead_tuple_len}
        };
    }
}

sub add_indexes {
    my ($self, %options) = @_;

    $options{sql}->query(query => qq{
        SELECT current_database() as dbname, relname, (pgstatindex(oid)).* from pg_class where relkind = 'i' AND relpersistence <> 't'
    });

    while (my $row = $options{sql}->fetchrow_hashref()) {
        $self->{databases}->{ $row->{dbname} } = { tables => {}, indexes => {} }
            if (!defined($self->{databases}->{ $row->{dbname} }));

        if (defined($self->{option_results}->{filter_index}) && $self->{option_results}->{filter_index} ne '' &&
            $row->{relname} !~ /$self->{option_results}->{filter_index}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $row->{relname} . "': no matching filter.", debug => 1);
            next
        }
        next if (defined($self->{option_results}->{filter_size}) && $self->{option_results}->{filter_size} =~ /^\d+$/ &&
            $row->{index_size} < $self->{option_results}->{filter_size});

        $self->{databases}->{ $row->{dbname} }->{indexes}->{ $row->{relname} } = {
            used => $row->{index_size},
            avg_leaf_density => $row->{avg_leaf_density} =~ /^[0-9\.]+$/ ? $row->{avg_leaf_density} : undef
        };
    }
}


sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();

    $self->{databases} = {};
    $self->add_tables(sql => $options{sql});
    $self->add_indexes(sql => $options{sql});
}

1;

__END__

=head1 MODE

Check tables and btrees bloat.

=over 8

Filter databases by state.

=item B<--filter-table>

Filter tables by name (can be a regexp).

=item B<--filter-index>

Filter indexes by name (can be a regexp).

=item B<--filter-size>

Filter tables and indexes by size (in bytes) keeping only sizes greater than the given value.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'table-usage', 'table-free', 'table-dead-tuple',
'index-usage', 'index-leaf-density'.

=back

=cut
