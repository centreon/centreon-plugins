#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::paloalto::api::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);

sub custom_vsys_active_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => $self->{label},
        nlabel => $self->{nlabel},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{sessions_active},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{sessions_max} != 0 ? $self->{result_values}->{sessions_max} : undef
    );
}

sub custom_active_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => $self->{label},
        nlabel => $self->{nlabel},
        value => $self->{result_values}->{sessions_active},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{sessions_max} != 0 ? $self->{result_values}->{sessions_max} : undef
    );
}

sub custom_active_output {
    my ($self, %options) = @_;

    return sprintf('active: %s (%s)',
        $self->{result_values}->{sessions_active},
        $self->{result_values}->{sessions_max} != 0 ? $self->{result_values}->{sessions_max} : '-'
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Sessions ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output', skipped_code => { NO_VALUE => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'active', nlabel => 'sessions.active.count', set => {
                key_values => [ { name => 'sessions_active' }, { name => 'sessions_max' } ],
                closure_custom_output => $self->can('custom_active_output'),
                closure_custom_perfdata => $self->can('custom_active_perfdata')
            }
        },
        { label => 'active-prct', nlabel => 'sessions.active.percentage', display_ok => 0, set => {
                key_values => [ { name => 'sessions_active_prct' } ],
                output_template => 'active: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        },
        { label => 'active-tcp', nlabel => 'sessions.active.tcp.count', set => {
                key_values => [ { name => 'sessions_tcp' } ],
                output_template => 'TCP: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'active-udp', nlabel => 'sessions.active.udp.count', set => {
                key_values => [ { name => 'sessions_udp' } ],
                output_template => 'UDP: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'active-icmp', nlabel => 'sessions.active.icmp.count', set => {
                key_values => [ { name => 'sessions_icmp' } ],
                output_template => 'ICMP: %s',
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        type       => 'op',
        cmd        => '<show><session><info/></session></show>',
        ForceArray => []
    );

    $self->{global} = {
        sessions_max    => $result->{'num-max'},
        sessions_active => $result->{'num-active'},
        sessions_udp    => $result->{'num-udp'},
        sessions_tcp    => $result->{'num-tcp'},
        sessions_icmp   => $result->{'num-icmp'}
    };

    $self->{global}->{sessions_active_prct} = $self->{global}->{sessions_active} * 100 / $self->{global}->{sessions_max}
        if ($self->{global}->{sessions_max} != 0);
}

1;

__END__

=head1 MODE

Check sessions.

=over 8

=item B<--warning-active>

Warning threshold for active sessions.

=item B<--critical-active>

Critical threshold for active sessions.

=item B<--warning-active-prct>

Warning threshold for active sessions in percent.

=item B<--critical-active-prct>

Critical threshold for for active sessions in percent.

=item B<--warning-active-udp>

Warning threshold for active UDP sessions.

=item B<--critical-active-udp>

Critical threshold for active UDP sessions.

=item B<--warning-active-tcp>

Warning threshold for active TCP sessions.

=item B<--critical-active-tcp>

Critical threshold for active TCP sessions.

=item B<--warning-active-icmp>

Warning threshold for active ICMP sessions.

=item B<--critical-active-icmp>

Critical threshold for active ICMP sessions.

=back

=cut
