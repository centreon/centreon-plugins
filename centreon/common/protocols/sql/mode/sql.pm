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

package centreon::common::protocols::sql::mode::sql;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);

sub custom_value_output {
    my ($self, %options) = @_;

    return sprintf($self->{instance_mode}->{option_results}->{format}, $self->{result_values}->{value});
}

sub custom_value_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{instance_mode}->{option_results}->{perfdata_name},
        unit => $self->{instance_mode}->{option_results}->{perfdata_unit},
        value => $self->{result_values}->{value},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => $self->{instance_mode}->{option_results}->{perfdata_min},
        max => $self->{instance_mode}->{option_results}->{perfdata_max}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'value', set => {
                key_values => [ { name => 'value' } ],
                closure_custom_output => $self->can('custom_value_output'),
                closure_custom_perfdata => $self->can('custom_value_perfdata')
            }
        },
        { label => 'execution-time', nlabel => 'sqlrequest.execution.time.seconds', display_ok => 0, set => {
                key_values => [ { name => 'time' } ],
                output_template => 'execution time: %.3f second(s)',
                perfdatas => [
                    { template => '%.3f', min => 0, unit => 's' }
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
        'sql-statement:s' => { name => 'sql_statement' },
        'format:s'        => { name => 'format', default => 'SQL statement result : %i.' },
        'perfdata-unit:s' => { name => 'perfdata_unit', default => '' },
        'perfdata-name:s' => { name => 'perfdata_name', default => 'value' },
        'perfdata-min:s'  => { name => 'perfdata_min', default => '' },
        'perfdata-max:s'  => { name => 'perfdata_max', default => '' },
        'warning:s'       => { name => 'warning', redirect => 'warning-value' },
        'critical:s'      => { name => 'critical', redirect => 'critical-value' }
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
    if (!defined($self->{option_results}->{format}) || $self->{option_results}->{format} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify '--format' option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    
    my $timing0 = [gettimeofday];
    $options{sql}->query(query => $self->{option_results}->{sql_statement});
    my $value = $options{sql}->fetchrow_array();
    $self->{global} = {
        value => $value,
        time => tv_interval($timing0, [gettimeofday])
    };

    $options{sql}->disconnect();
}

1;

__END__

=head1 MODE

Check SQL statement.

=over 8

=item B<--sql-statement>

SQL statement that returns a number.

=item B<--format>

Output format (Default: 'SQL statement result : %i.').

=item B<--perfdata-unit>

Perfdata unit in perfdata output (Default: '')

=item B<--perfdata-name>

Perfdata name in perfdata output (Default: 'value')

=item B<--perfdata-min>

Minimum value to add in perfdata output (Default: '')

=item B<--perfdata-max>

Maximum value to add in perfdata output (Default: '')

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'value', 'execution-time'.

=back

=cut
