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
#FIXME: correct handling of multi-rows queries

package centreon::common::protocols::sql::mode::sqlstring;

use base qw(centreon::plugins::templates::counter);
use strict;
use warnings;

my $instance_mode;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "sql-statement:s"         => { name => 'sql_statement', },
                                  "format-prefix:s"         => { name => 'format_prefix', default => 'SQL statement result: '},
                                  "format-suffix:s"         => { name => 'format_suffix', default => ' '},
                                  "warning-status:s"        => { name => 'warning_status', },
                                  "critical-status:s"       => { name => 'critical_status', },
                                  "unknown-status:s"        => { name => 'unknown_status', },
                                });
    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'rows', type => 1, cb_prefix_output => 'custom_prefix_output', cb_suffix_output => 'custom_suffix_output', message_multiple => 'All rows are ok' },
    ];

    $self->{maps_counters}->{rows} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'string' }, { name => 'key' } ],
                output_template => '%s',
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
                 perfdatas => [ ]
            }
        },
    ];
}

sub manage_selection {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};
    $self->{sql}->connect();
    $self->{sql}->query(query => $self->{option_results}->{sql_statement});
    $self->{rows} = {};
    my $row = '';
    my $rownum = 1;
    while ($row = $self->{sql}->fetchrow_hashref()) {
        # preparing a 'key' column to handle multi-rows
        if (defined($row->{key}) && $row->{key} ne '' ) {
            $self->{rows}->{$row->{key}.'.'.$row->{value}} = { key => $row->{key}, string => $row->{value} };
        } else {
            $self->{rows}->{'string'.$rownum.'.'.$row->{value}} = { key => 'string'.$rownum, string => $row->{value} };
        }
        $rownum++;
    }
}

sub custom_prefix_output {
    my ($self, %options) = @_;
    if (defined($instance_mode->{option_results}->{format_prefix})) {
        return $instance_mode->{option_results}->{format_prefix};
    }
    return "Status string: ";
}

sub custom_suffix_output {
    my ($self, %options) = @_;
    if (defined($instance_mode->{option_results}->{format_suffix})) {
        return $instance_mode->{option_results}->{format_suffix};
    }
    return " ";
}

sub check_options {
    my ($self, %options) = @_;
    #$self->SUPER::init(%options);
    $self->SUPER::check_options(%options);
    $instance_mode = $self;
    if (!defined($instance_mode->{option_results}->{sql_statement}) || $instance_mode->{option_results}->{sql_statement} eq '') {
        $instance_mode->{output}->add_option_msg(short_msg => "Need to specify '--sql-statement' option.");
        $instance_mode->{output}->option_exit();
    }
    $instance_mode->change_macros();
}

sub change_macros {
    my ($self, %options) = @_;
    foreach (('warning_status', 'critical_status', 'unknown_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$value->{$1}/g;
        }
    }
}

sub custom_status_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    for my $value (values %{$instance_mode->{rows}}) {
        if (defined($instance_mode->{option_results}->{critical_status}) &&
                $instance_mode->{option_results}->{critical_status} ne '' && 
                eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) &&
                $instance_mode->{option_results}->{warning_status} ne '' &&
                eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        } elsif (defined($instance_mode->{option_results}->{unknown_status}) &&
                $instance_mode->{option_results}->{unknown_status} ne '' &&
                eval "$instance_mode->{option_results}->{unknown_status}" ) {
            $status = 'unknown';
        }
    }
    return $status;
}

1;

__END__

=head1 MODE

Check SQL statement providing a string.

=over 8

=item B<--sql-statement>

SQL statement that returns a string. 
NOTICE: You need to write your query beginning with 'SELECT <field> AS value' (ie. at least one output column must be named 'value') for this plugin to work properly.
If you need to assess a numeric value, please refer to sql mode.

=item B<--unknown-status>

Set unknown condition (if statement syntax) for status evaluation.
Can use special variables like: %{result_string} or any %{column_name} from the query output.

Example: '%{result_string} !~ /ok|crit|warn/i'

=item B<--warning-status>

Set warning condition (if statement syntax) for status evaluation.
Can use special variables like: %{result_string} or any %{column_name} from the query output.

Example: '%{result_string} =~ /warn/i'

=item B<--critical-status>

Set critical condition (if statement syntax) for status evaluation.
Can use special variables like: %{result_string} or any %{column_name} from the query output.

Example: '%{result_string} =~ /crit/i'

=item B<--format-prefix>

Output prefix.

Default: 'SQL statement result : "%s".'

=item B<--format-suffix>

Output suffix.

Default: ' '

=back

=cut
