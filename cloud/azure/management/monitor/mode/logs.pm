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

sub custom_output {
    my ($self, %options) = @_;
    
    return sprintf(
	    "Count results: '%d'",
        $self->{result_values}->{count_absolute}
    );
}

sub custom_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'count',
        value => $self->{result_values}->{count_absolute},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'logs', type => 0 },
    ];

    $self->{maps_counters}->{logs} = [
        { label => 'count', set => {
                key_values => [ { name => 'count' } ],
                closure_custom_output => $self->can('custom_output'),
                closure_custom_perfdata => $self->can('custom_perfdata'),
                threshold_use => 'count_absolute',
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "workspace-id:s"        => { name => 'workspace_id' },
        "query:s"     => { name => 'query'},
        "timespan:s"  => { name => 'timespan', default => 'PT5M' },
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

    $self->{az_workspace_id} = $self->{option_results}->{workspace_id};
    $self->{az_query} =  $self->{option_results}->{query};
    $self->{az_timespan} = $self->{option_results}->{timespan};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $workspaceId = $self->{az_workspace_id};
    my $timespan = $self->{az_timespan};

    if ($self->{az_workspace_id} =~ /^\/v1\/workspaces\/(.*)\/query$/i) {
        $workspaceId = $1;
    }

    my $body = {
        'query'    => $self->{az_query},
        'timespan' => $timespan
    };
    my $status = $options{custom}->azure_post_query(
        workspace => $workspaceId,
        body => $body,
    );

#use Data::Dumper;
#print Dumper($status);
    foreach my $values (@{$status->{tables}}) {
        foreach my $result (@{$values->{rows}}) {
            foreach my $count (@{$result}) {
                $self->{logs} = {
                    count => $count
                };
            }
        }
    }
}

1;

__END__

=head1 MODE

Check logs queries


=over 8

=item B<--workspace-id>

Set workspace id (Required).

=item B<--query>

Set query (Required).

=item B<--timespan>

Set timespan. (By default 'PT5M')

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: count.

=back

=cut
