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

package storage::emc::unisphere::restapi::mode::replications;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use storage::emc::unisphere::restapi::mode::components::resources qw($replication_status $health_status);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_health_status_output {
    my ($self, %options) = @_;

    return 'health status: ' . $self->{result_values}->{health_status};
}

sub custom_replication_status_output {
    my ($self, %options) = @_;

    return 'replication status: ' . $self->{result_values}->{repl_status};
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'replication', type => 1, cb_prefix_output => 'prefix_replication_output', message_multiple => 'All replications are ok' }
    ];
    
    $self->{maps_counters}->{replication} = [
        {
            label => 'health-status',
            type => 2,
            unknown_default => '%{health_status} =~ /unknown/i',
            warning_default => '%{health_status} =~ /ok_but|degraded|minor/i',
            critical_default => '%{health_status} =~ /major|critical|non_recoverable/i',
            set => {
                key_values => [ { name => 'health_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_health_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'replication-status',
            type => 2,
            unknown_default => '%{repl_status} =~ /unknown/i',
            warning_default => '%{repl_status} =~ /syncing/i',
            critical_default => '%{repl_status} =~ /inconsistent/i',
            set => {
                key_values => [ { name => 'repl_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_replication_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });
    
    return $self;
}

sub prefix_replication_output {
    my ($self, %options) = @_;
    
    return "Replication '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(url_path => '/api/types/replicationSession/instances?fields=name,health,syncState');

    $self->{replication} = {};
    foreach (@{$results->{entries}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{content}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping replication '" . $_->{content}->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{replication}->{ $_->{content}->{id} } = {
            display => $_->{content}->{name},
            health_status => $health_status->{ $_->{content}->{health}->{value} },
            repl_status => $replication_status->{ $_->{content}->{syncState} },
        };
    }

    if (scalar(keys %{$self->{replication}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No replications found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check replication status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^health'

=item B<--filter-name>

Filter replication name (can be a regexp).

=item B<--unknown-health-status>

Set unknown threshold for status (Default: '%{health_status} =~ /unknown/i').
Can used special variables like: %{health_status}, %{display}

=item B<--warning-health-status>

Set warning threshold for status (Default: '%{health_status} =~ /ok_but|degraded|minor/i').
Can used special variables like: %{health_status}, %{display}

=item B<--critical-health-status>

Set critical threshold for status (Default: '%{health_status} =~ /major|critical|non_recoverable/i').
Can used special variables like: %{health_status}, %{display}

=item B<--unknown-repl-status>

Set unknown threshold for status (Default: '%{repl_status} =~ /unknown/i').
Can used special variables like: %{repl_status}, %{display}

=item B<--warning-repl-status>

Set warning threshold for status (Default: '%{repl_status} =~ /syncing/i').
Can used special variables like: %{repl_status}, %{display}

=item B<--critical-repl-status>

Set critical threshold for status (Default: '%{repl_status} =~ /inconsistent/i').
Can used special variables like: %{repl_status}, %{display}

=back

=cut
