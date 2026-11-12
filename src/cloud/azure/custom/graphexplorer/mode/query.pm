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

package cloud::azure::management::graphexplorer::mode::query;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_match_output {
    my ($self, %options) = @_;

    my $msg;
    my $message;

    if (defined($self->{instance_mode}->{option_results}->{custom_output}) && $self->{instance_mode}->{option_results}->{custom_output} ne '') {
        eval {
            local $SIG{__WARN__} = sub { $message = $_[0]; };
            local $SIG{__DIE__}  = sub { $message = $_[0]; };
            $msg = sprintf($self->{instance_mode}->{option_results}->{custom_output}, $self->{result_values}->{match});
        };
    } else {
        $msg = sprintf("Resource Graph query returned '%d' result(s)", $self->{result_values}->{match});
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
        { label => 'match', nlabel => 'resourcegraph.query.match.count', set => {
                key_values               => [ { name => 'match' } ],
                closure_custom_output    => $self->can('custom_match_output'),
                perfdatas                => [
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
        'query:s'         => { name => 'query' },
        'custom-output:s' => { name => 'custom_output' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{query}) || $self->{option_results}->{query} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --query option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->azure_get_resource_graph(
        query => $self->{option_results}->{query}
    );

    my $count = 0;
    if (defined($response->{data}) && ref($response->{data}) eq 'ARRAY') {
        $count = scalar(@{$response->{data}});
    } elsif (defined($response->{count})) {
        $count = $response->{count};
    }

    if (defined($response->{resultTruncated}) && $response->{resultTruncated} eq 'true') {
        $self->{output}->output_add(long_msg =>
            "Warning: result set is truncated (totalRecords: " . $response->{totalRecords} . "). "
            . "Use 'top' in your KQL query to reduce the result set."
        );
    }

    if (defined($response->{data}) && ref($response->{data}) eq 'ARRAY') {
        foreach my $row (@{$response->{data}}) {
            $self->{output}->output_add(long_msg => join(', ', map { $_ . '=' . (defined($row->{$_}) ? $row->{$_} : '') } keys %{$row}));
        }
    }

    $self->{global} = { match => $count };
}

1;

__END__

=head1 MODE

Run a KQL query against Azure Resource Graph and count the number of results.

Sample command:
perl centreon_plugins.pl --plugin=cloud::azure::management::graphexplorer::plugin \
  --custommode api --mode query \
  --subscription=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX \
  --tenant=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX \
  --client-id=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX \
  --client-secret=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX \
  --query "Resources | where type =~ 'microsoft.compute/virtualmachines' | where properties.powerState.code == 'PowerState/running'" \
  --custom-output='Running VMs: %d' \
  --warning-match=10 --critical-match=20
OK: Running VMs: 5 | 'resourcegraph.query.match.count'=5;10;20;0;

=over 8

=item B<--query>

KQL query to run against Azure Resource Graph (required).
See https://docs.microsoft.com/en-us/azure/governance/resource-graph/concepts/query-language

=item B<--custom-output>

Custom output string in printf format. Use %d as placeholder for the result count.
Example: 'Running VMs: %d'

=item B<--warning-match>

Warning threshold on the number of results returned by the query.

=item B<--critical-match>

Critical threshold on the number of results returned by the query.

=back

=cut
