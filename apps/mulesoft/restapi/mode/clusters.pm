#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and cluster monitoring for
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

package apps::mulesoft::restapi::mode::clusters;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    return my $msg = sprintf('Id: %s, Status: %s', $self->{result_values}->{id}, $self->{result_values}->{status});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'clusters', type => 1, cb_prefix_output => 'prefix_cluster_output', message_multiple => 'All clusters are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'mulesoft.clusters.total.count', set => {
                key_values      => [ { name => 'total' }  ],
                output_template => "Total : %s",
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'running', nlabel => 'mulesoft.clusters.status.running.count', set => {
                key_values      => [ { name => 'running' }  ],
                output_template => "Running : %s",
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'disconnected', nlabel => 'mulesoft.clusters.status.disconnected.count', set => {
                key_values      => [ { name => 'disconnected' }  ],
                output_template => "Disconnected : %s",
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        }
   ];

    $self->{maps_counters}->{clusters} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'id' }, { name => 'status' }, { name => 'name'}, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Total clusters ";
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "cluster '" . $options{instance_value}->{name} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { started => 0, stopped => 0, failed => 0 };
    $self->{clusters} = {};
    my $result = $options{custom}->list_objects(api_type => 'arm', endpoint => '/clusters');
    foreach ('running', 'disconnected') { $self->{global}->{$_} = 0; };
    
    foreach my $cluster (@{$result}) {
        next if ( defined($self->{option_results}->{filter_name})
            && $self->{option_results}->{filter_name} ne ''
            && $cluster->{name} !~ /$self->{option_results}->{filter_name}/ );
        $self->{clusters}->{$cluster} = {
            display     => $cluster,
            id          => $cluster->{id},
            name        => $cluster->{name},
            status      => $cluster->{status},
        };

        $self->{global}->{running}++ if $cluster->{status} =~ m/RUNNING/;
        $self->{global}->{disconnected}++ if $cluster->{status} =~ m/DISCONNECTED/;
    }

    if (scalar(keys %{$self->{clusters}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No cluster found.");
        $self->{output}->option_exit();
    }

    $self->{global}->{total} = scalar (keys %{$self->{clusters}});
}

1;

__END__

=head1 MODE

Check Mulesoft Anypoint clusters status.

Example:
perl centreon_plugins.pl --plugin=apps::mulesoft::restapi::plugin --mode=clusters
--environment-id='1234abc-56de-78fg-90hi-1234abcdefg' --organization-id='1234abcd-56ef-78fg-90hi-1234abcdefg'
--api-username='myapiuser' --api-password='myapipassword' --verbose

More information on'https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/'.

=over 8

=item B<--filter-name>

Filter by cluster name (Regexp can be used).
Example: --filter-name='^cluster1$'

=item B<--warning-status>

Set warning threshold for status (Default: '').
Threshold can be matched on %{name}, %{id} or %{status} and Regexp can be used.
Typical syntax: --warning-status='%{status} ne "RUNNING"'

=item B<--critical-status>

Set warning threshold for status (Default: '').
Threshold can be matched on %{name}, %{id} or %{status} and Regexp can be used.
Typical syntax: --critical-status='%{status} ~= m/DISCONNECTED/'


=back

=cut
