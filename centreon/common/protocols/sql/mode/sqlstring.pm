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

package centreon::common::protocols::sql::mode::sqlstring;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "sql-statement:s"   		=> { name => 'sql_statement', },
                                  "format:s"                => { name => 'format', default => 'SQL statement result : "%s".'},
                                  "format-field:s"          => { name => 'format_field', default => '%{result_string}'},
                                  "warning-status:s"        => { name => 'warning_status', },
                                  "critical-status:s"       => { name => 'critical_status', },
                                  "unknown-status:s"        => { name => 'unknown_status', },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    if (!defined($self->{option_results}->{sql_statement}) || $self->{option_results}->{sql_statement} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify '--sql-statement' option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{format}) || $self->{option_results}->{format} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify '--format' option.");
        $self->{output}->option_exit();
    }
    $self->change_macros();
}

sub change_macros {
    my ($self, %options) = @_;
    foreach (('warning_status', 'critical_status', 'unknown_status', 'format_field')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$value->{$1}/g;
        }
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};
    $self->{sql}->connect();
    $self->{sql}->query(query => $self->{option_results}->{sql_statement});
    my $value = $self->{sql}->fetchrow_hashref();
	my $exit_code = 'ok';
	if (defined($self->{option_results}->{critical_status}) && $self->{option_results}->{critical_status} ne '' && eval "$self->{option_results}->{critical_status}" ) {
        $exit_code= 'critical';
    } elsif (defined($self->{option_results}->{warning_status}) && $self->{option_results}->{warning_status} ne '' && eval "$self->{option_results}->{warning_status}" ) {
        $exit_code = 'warning';
    } elsif (defined($self->{option_results}->{unknown_status}) && $self->{option_results}->{unknown_status} ne '' && eval "$self->{option_results}->{unknown_status}" ) {
        $exit_code = 'unknown';
	}

    $self->{output}->output_add(severity => $exit_code, short_msg => sprintf($self->{option_results}->{format}, eval $self->{option_results}->{format_field}));
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check SQL statement providing a string.

=over 8

=item B<--sql-statement>

SQL statement that returns a string. 
NOTICE: Unless you define --format-field otherwise, you need to write your query beginning with 'SELECT <field> AS result_string' (ie. at least one output column must be named 'result_string') for this plugin to work properly.
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

=item B<--format>

Output format (printf syntax).

Default: 'SQL statement result : "%s".'

=item B<--format-field>

Output field(s) the --format argument refers to (printf arguments #2, #3, ...).

Default: '%{result_string}'

=back

=cut
