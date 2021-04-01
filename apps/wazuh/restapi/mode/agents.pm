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

package apps::wazuh::restapi::mode::agents;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf('status: %s [node name: %s]', 
        $self->{result_values}->{status},
        $self->{result_values}->{node_name}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'agent', type => 1, cb_prefix_output => 'prefix_agent_output', message_multiple => 'All agents are ok' }
    ];
    
    $self->{maps_counters}->{global} = [];
    foreach ('active', 'pending', 'neverconnected', 'disconnected') {
        push @{$self->{maps_counters}->{global}}, {
            label => $_, nlabel => 'agents.' . $_ . '.count', display_ok => 0, set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { value => $_ , template => '%s', min => 0 },
                ],
            }
        };
    }
    
    $self->{maps_counters}->{agent} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' }, { name => 'node_name' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'       => { name => 'filter_name' },
        'warning-status:s'    => { name => 'warning_status', default => '' },
        'critical-status:s'   => { name => 'critical_status', default => '' },
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
    
    return "Total agents ";
}

sub prefix_agent_output {
    my ($self, %options) = @_;
    
    return "Agent '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { active => 0, pending => 0, neverconnected => 0, disconnected => 0 };
    $self->{agent} = {};
    my $result = $options{custom}->request(path => '/agents?select=name,status,node_name');
    foreach (@{$result->{data}->{items}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping agent '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }

        my $status = lc($_->{status});
        $self->{agent}->{$_->{id}} = {
            display => $_->{name},
            node_name => $_->{node_name},
            status => $status,
        };
        
        $self->{global}->{$status}++;
    }
}

1;

__END__

=head1 MODE

Check wazuh agents.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--filter-name>

Filter agent name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{node_name}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}, %{node_name}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'active', 'pending', 'neverconnected', 'disconnected'.

=back

=cut
