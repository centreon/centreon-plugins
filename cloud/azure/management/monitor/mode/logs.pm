#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package cloud::azure::management::monitor::mode::logs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'logs.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total logs: %s',
                perfdatas => [
                    { value => 'total', template => '%s', min => 0 }
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
        'workspace-id:s' => { name => 'workspace_id' },
        'query:s'        => { name => 'query'}
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

    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : 'PT5M';
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($log_results) = $options{custom}->azure_get_log_analytics(
        workspace_id => $self->{option_results}->{workspace_id},
        query => $self->{option_results}->{query},
        interval => $self->{az_interval}
    );

    $self->{global} = { total => 0 };
    foreach my $table (@{$log_results->{tables}}) {
        foreach (@{$table->{rows}}) {
            $self->{global}->{total} += $_->[0];
        }
    }
}

1;

__END__

=head1 MODE

Check logs queries.
You should set option: --management-endpoint='https://api.loganalytics.io'

=over 8

=item B<--workspace-id>

Set workspace id (Required).

=item B<--query>

Set query (Required).
Syntax: https://docs.microsoft.com/en-us/azure/kusto/query/

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: count.

=back

=cut
