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

package apps::backup::rapidrecovery::snmp::mode::agent;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status : ' . $self->{result_values}->{status};
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'agent', type => 1, cb_prefix_output => 'prefix_agent_output', message_multiple => 'All agents are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', display_ok => 0, nlabel => 'agents.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total agents: %d',
                perfdatas => [
                    { value => 'total', template => '%d', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{agent} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'recoverypoints', nlabel => 'agent.recoverypoints.count', set => {
                key_values => [ { name => 'recovery_points' }, { name => 'display' } ],
                output_template => 'recovery points: %s',
                perfdatas => [
                    { value => 'recovery_points', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '%{status} =~ /unreachable/i' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} =~ /failed|authenticationError/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

sub prefix_agent_output {
    my ($self, %options) = @_;
    
    return "Agent '" . $options{instance_value}->{display} . "' ";
}

my $map_status = {
    0 => 'online', 1 => 'pendingFailover',
    2 => 'unreachable', 3 => 'authenticationError',
    4 => 'failed', 5 => 'loading'
};

my $mapping = {
    agentName                => { oid => '.1.3.6.1.4.1.674.11000.1000.200.100.300.1.3' },
    agentStatus              => { oid => '.1.3.6.1.4.1.674.11000.1000.200.100.300.1.5', map => $map_status },
    agentRecoveryPointsCount => { oid => '.1.3.6.1.4.1.674.11000.1000.200.100.300.1.7' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_agentEntry = '.1.3.6.1.4.1.674.11000.1000.200.100.300.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_agentEntry,
        start => $mapping->{agentName}->{oid},
        end => $mapping->{agentRecoveryPointsCount}->{oid},
        nothing_quit => 1
    );

    $self->{agent} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{agentName}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{agentName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{agentName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{agent}->{$instance} = {
            display => $result->{agentName},
            status => $result->{agentStatus},
            recovery_points => $result->{agentRecoveryPointsCount}
        };
    }

    $self->{global} = { total => scalar(keys %{$self->{agent}}) };
}

1;

__END__

=head1 MODE

Check agents.

=over 8

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{status} =~ /unreachable/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /failed|authenticationError/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'recoverypoints'.

=item B<--filter-name>

Filter agent name (can be a regexp).

=back

=cut
