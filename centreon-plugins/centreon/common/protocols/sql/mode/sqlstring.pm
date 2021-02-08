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

package centreon::common::protocols::sql::mode::sqlstring;

use base qw(centreon::plugins::templates::counter);
use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'rows', type => 1, message_multiple => "SQL Query is OK" },
    ];

    $self->{maps_counters}->{rows} = [
        { label => 'string', threshold => 0, set => {
                key_values => [ { name => 'key_field' }, { name => 'value_field' } ],
                closure_custom_calc => $self->can('custom_string_calc'),
                closure_custom_output => $self->can('custom_string_output'),
                closure_custom_threshold_check => $self->can('custom_string_threshold'),
                closure_custom_perfdata => sub { return 0; },
            }
        },
    ];
}

sub custom_string_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{key_field} = $options{new_datas}->{$self->{instance} . '_key_field'};
    $self->{result_values}->{value_field} = $options{new_datas}->{$self->{instance} . '_value_field'};

    return 0;
}

sub custom_string_output {
    my ($self, %options) = @_;

    my $msg;
    my $message;

    if (defined($self->{instance_mode}->{option_results}->{printf_format}) && $self->{instance_mode}->{option_results}->{printf_format} ne '') {
        eval {
            local $SIG{__WARN__} = sub { $message = $_[0]; };
            local $SIG{__DIE__} = sub { $message = $_[0]; };
            $msg = sprintf("$self->{instance_mode}->{option_results}->{printf_format}", eval $self->{instance_mode}->{option_results}->{printf_value});
        };
    } else {
        $msg = sprintf("'%s'", $self->{result_values}->{value_field});
    }

    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'output value issue: ' . $message);
    }
    return $msg;
}

sub custom_string_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($self->{instance_mode}->{option_results}->{critical_string}) && $self->{instance_mode}->{option_results}->{critical_string} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{critical_string}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{warning_string}) && $self->{instance_mode}->{option_results}->{warning_string} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{warning_string}") {
            $status = 'warning';
        }
    };

    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'threshold regex issue: ' . $message);
    }

    return $status;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "sql-statement:s"         => { name => 'sql_statement' },
        "key-column:s"            => { name => 'key_column' },
        "value-column:s"          => { name => 'value_column' },
        "warning-string:s"        => { name => 'warning_string', default => '' },
        "critical-string:s"       => { name => 'critical_string', default => '' },
        "printf-format:s"         => { name => 'printf_format' },
        "printf-value:s"          => { name => 'printf_value' },
        "dual-table"              => { name => 'dual_table' },
        "empty-sql-string:s"      => { name => 'empty_sql_string', default => 'No row returned or --key-column/--value-column do not correctly match selected field' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{sql_statement}) || $self->{option_results}->{sql_statement} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify '--sql-statement' option.");
        $self->{output}->option_exit();
    }

    $self->change_macros(macros => ['warning_string', 'critical_string']);
}

sub manage_selection {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};
    $self->{sql}->connect();
    $self->{sql}->query(query => $self->{option_results}->{sql_statement});
    $self->{rows} = {};
    my $row_count = 0;

    while (my $row = $self->{sql}->fetchrow_hashref()) {
        if (defined($self->{option_results}->{dual_table})) {
            $row->{$self->{option_results}->{value_column}} = delete $row->{keys %{$row}};
            foreach (keys %{$row}) {
                $row->{$self->{option_results}->{value_column}} = $row->{$_};
            }
        }
        if (!defined($self->{option_results}->{key_column})) {
            $self->{rows}->{$self->{option_results}->{value_column} . $row_count} = { key_field => $row->{$self->{option_results}->{value_column}},
                                                                                      value_field => $row->{$self->{option_results}->{value_column}}};
            $row_count++;
        } else {
            $self->{rows}->{$self->{option_results}->{key_column} . $row_count} = { key_field => $row->{$self->{option_results}->{key_column}},
                                                                                    value_field => $row->{$self->{option_results}->{value_column}}};
            $row_count++;
        }
    }

    $self->{sql}->disconnect();
    if (scalar(keys %{$self->{rows}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => $self->{option_results}->{empty_sql_string});
        $self->{output}->option_exit();
    }

}

1;

__END__

=head1 MODE

Check SQL statement to query string pattern (You cannot have more than to fiels in select)

=over 8

=item B<--sql-statement>

SQL statement that returns a string.

=item B<--key-column>

Key column (must be one of the selected field). NOT mandatory if you select only one field

=item B<--value-column>

Value column (must be one of the selected field). MANDATORY

=item B<--printf-format>

Specify a custom output message relying on printf formatting

=item B<--printf-value>

Specify scalar used to replace in printf
(Can be: $self->{result_values}->{key_field}, $self->{result_values}->{value_field})

=item B<--warning-string>

Set warning condition (if statement syntax) for status evaluation.
(Can be: %{key_field}, %{value_field})
e.g --warning-string '%{key_field} eq 'Central' && %{value_field} =~ /127.0.0.1/'

=item B<--critical-string>

Set critical condition (if statement syntax) for status evaluation.
(Can be: %{key_field} or %{value_field})

=item B<--dual-table>

Set this option to ensure compatibility with dual table and Oracle.

=item B<--empty-sql-string>

Set this option to change the output message when the sql statement result is empty.
(Default: 'No row returned or --key-column/--value-column do not correctly match selected field')

=back

=cut
