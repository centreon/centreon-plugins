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

package cloud::azure::management::loganalytics::mode::kustoquery;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_match_output {
    my ($self, %options) = @_;

    my $msg;
    my $message;

    if (defined($self->{instance_mode}->{option_results}->{custom_output}) && $self->{instance_mode}->{option_results}->{custom_output} ne '') {
        eval {
            local $SIG{__WARN__} = sub { $message = $_[0]; };
            local $SIG{__DIE__} = sub { $message = $_[0]; };
            $msg = sprintf("$self->{instance_mode}->{option_results}->{custom_output}", eval $self->{result_values}->{match});
        };
    } else {
        $msg = sprintf("Total logs match '%d'", $self->{result_values}->{match});
    }

    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'printf substitution issue: ' . $message);
    }
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'match', nlabel => 'match.count', set => {
                key_values => [ { name => 'match' } ],
                closure_custom_output => $self->can('custom_match_output'),
                perfdatas => [
                    { template => '%s', min => 0 }
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
        'custom-output:s'   => { name => 'custom_output'},
        'query:s'           => { name => 'query'},
        'timespan:s'        => { name => 'timespan' },
        'workspace-id:s'    => { name => 'workspace_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{workspace_id}) || $self->{option_results}->{workspace_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify  --workspace-id <id>.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{query}) || $self->{option_results}->{query} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify a query.");
        $self->{output}->option_exit();
    }

}

sub manage_selection {
    my ($self, %options) = @_;

    my ($log_results) = $options{custom}->azure_get_log_analytics(
        workspace_id => $self->{option_results}->{workspace_id},
        query => $self->{option_results}->{query},
        timespan => $self->{option_results}->{timespan}
    );

    $self->{global} = { match => 0 };
    foreach my $table (@{$log_results->{tables}}) {
        foreach (@{$table->{rows}}) {
            $self->{global}->{match}++;
        }
    }
}

1;

__END__

=head1 MODE

Perform a Kusto query and count results

Sample command: 
perl centreon_plugins.pl --plugin=cloud::azure::management::loganalytics::plugin \
--custommode api --management-endpoint='https://api.loganalytics.io' --mode kusto-query \
--subscription=***********************  --tenant=*********************** \
--client-id=*********************** --client-secret=*********************** --workspace-id=*********************** \
--query 'Heartbeat | summarize LastCall = max(TimeGenerated) by Computer | where LastCall > ago(3d)' \
--custom-output='Number of syslog %d'
OK: Number of Syslog '2' | 'match.count'=2;;;0;

=over 8

=item B<--custom-output>

Set a custom message to output in printf format.
Exemple: 'Number of Syslog message collected %d'

=item B<--query>

Set query (Required).
Syntax: https://docs.microsoft.com/en-us/azure/kusto/query/

=item B<--workspace-id>

Set workspace id (Required).

=item B<--timespan>

Set Timespan of the query (Do not use it if time filters is included in the 
query)
(Can be : PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H, PT24H).

=item B<--warning-match> B<--critical-match>

Thresholds.

=back

=cut
