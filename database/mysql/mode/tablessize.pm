#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package database::mysql::mode::tablessize;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'table', type => 1, cb_prefix_output => 'prefix_table_output', message_multiple => 'All tables sizes are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total Size : %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'total', value => 'total_absolute', template => '%s',
                      unit => 'B', min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{table} = [
        { label => 'table', set => {
                key_values => [ { name => 'size' }, { name => 'display' } ],
                output_template => 'size : %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'table', value => 'size_absolute', template => '%s',
                      unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-db:s" => { name => 'filter_db' },
                                "filter-table:s" => { name => 'filter_table' },
                                });
    return $self;
}

sub prefix_table_output {
    my ($self, %options) = @_;

    return "Table '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    $self->{sql}->query(query => "SELECT table_schema AS DB, table_name AS NAME, ROUND(data_length + index_length)
                                  FROM information_schema.TABLES");
    my $result = $self->{sql}->fetchall_arrayref();

    if (!($self->{sql}->is_version_minimum(version => '5'))) {
        $self->{output}->add_option_msg(short_msg => "MySQL version '" . $self->{sql}->{version} . "' is not supported.");
        $self->{output}->option_exit();
    }

    $self->{global} = { total => 0 };
    $self->{table} = {};

    foreach my $row (@$result) {
        next if (!defined($$row[2]));
        if (defined($self->{option_results}->{filter_table}) && $self->{option_results}->{filter_table} ne '' &&
            $$row[1] !~ /$self->{option_results}->{filter_table}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $$row[0].'.'.$$row[1] . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_db}) && $self->{option_results}->{filter_db} ne '' &&
            $$row[0] !~ /$self->{option_results}->{filter_db}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $$row[0].'.'.$$row[1] . "': no matching filter.", debug => 1);
            next
        }
        $self->{table}->{$$row[0].'.'.$$row[1]} = { size => $$row[2], display => $$row[0].'.'.$$row[1] };
        $self->{global}->{total} += $$row[2] if defined($self->{table}->{$$row[0].'.'.$$row[1]});
    }
}

1;

__END__

=head1 MODE

Check size of one (or more) table from one (or more) databases

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--filter-db>

Filter DB name (can be a regexp).

=item B<--filter-table>

Filter table name (can be a regexp).

=item B<--warning-*>

Set warning threshold for number of user. Can be : 'total', 'table'

=item B<--critical-*>

Set critical threshold for number of user. Can be : 'total', 'table'

=back

=cut
