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

package apps::wallix::bastion::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_services_status_output {
    my ($self, %options) = @_;
    
    return sprintf('services status: %s', $self->{result_values}->{status});
}

sub system_long_output {
    my ($self, %options) = @_;

    return 'checking system';
}

sub prefix_sessions_output {
    my ($self, %options) = @_;

    return 'sessions ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'system', type => 3, cb_long_output => 'system_long_output', indent_long_output => '    ',
            group => [
                { name => 'services_status', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'sessions', type => 0, cb_prefix_output => 'prefix_sessions_output', message_separator => ' ', display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'requests', type => 0, display_short => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{services_status} = [
        { label => 'services-status', type => 2, critical_default => '%{status} eq "unreachable"', set => {
                key_values => [ { name => 'status' }, ],
                closure_custom_output => $self->can('custom_services_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{sessions} = [
        { label => 'sessions-total', nlabel => 'sessions.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'sessions-primary', nlabel => 'sessions.primary.count', set => {
                key_values => [ { name => 'primary' } ],
                output_template => 'primary: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'sessions-secondary', nlabel => 'sessions.secondary.count', set => {
                key_values => [ { name => 'secondary' } ],
                output_template => 'secondary: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'sessions-ghost', nlabel => 'sessions.ghost.count', set => {
                key_values => [ { name => 'ghost' } ],
                output_template => 'ghost: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{requests} = [
        { label => 'requests-pending', nlabel => 'requests.pending.count', set => {
                key_values => [ { name => 'pending' } ],
                output_template => 'requests pending: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping_status = {
        1 => 'running', 2 => 'unreachable'
    };
    my $mapping = {
        total_session     => { oid => '.1.3.6.1.4.1.30373.1.1.1' }, # totalSessionCount
        primary_session   => { oid => '.1.3.6.1.4.1.30373.1.1.2' }, # primarySessionCount
        secondary_session => { oid => '.1.3.6.1.4.1.30373.1.1.3' }, # secondarySessionCount
        ghost_session     => { oid => '.1.3.6.1.4.1.30373.1.1.4' }, # ghostSessionCount
        requests_pending  => { oid => '.1.3.6.1.4.1.30373.1.1.7' }, # pendingApprovalCount
        services_status   => { oid => '.1.3.6.1.4.1.30373.1.2.3', map => $mapping_status } # bastionStatus
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

    $self->{output}->output_add(short_msg => 'system is ok');

    $self->{system} = {
        global => {
            services_status => { status => $result->{services_status} },
            sessions => {
                total => $result->{total_session},
                primary => $result->{primary_session},
                secondary => $result->{secondary_session},
                ghost => $result->{ghost_session}
            },
            requests => { pending => $result->{requests_pending} }
        }
    };
}

1;

__END__

=head1 MODE

Check system usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--warning-services-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}

=item B<--critical-services-status>

Define the conditions to match for the status to be CRITICAL (default: '').
You can use the following variables: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'requests-pending', 'sessions-total', 'sessions-primary', 
'sessions-secondary', 'sessions-ghost'.

=back

=cut
