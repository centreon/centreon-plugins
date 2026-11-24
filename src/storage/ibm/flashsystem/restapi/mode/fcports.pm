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

package storage::ibm::flashsystem::restapi::mode::fcports;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_empty is_excluded is_not_empty);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_port_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'status: %s, speed: %s, attachment: %s',
        $self->{result_values}->{status},
        $self->{result_values}->{port_speed},
        $self->{result_values}->{attachment}
    );

    $msg .= sprintf(', host logins: %s', $self->{result_values}->{active_login_count})
        if (is_not_empty($self->{result_values}->{active_login_count}));

    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Fibre Channel ports: ' },
        { name => 'ports', type => COUNTER_TYPE_INSTANCE, prefix_output => "Port '%{name}' ",
          message_multiple => 'All Fibre Channel ports are active', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'detected', nlabel => 'fcports.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => '%s detected',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'active', nlabel => 'fcports.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => '%s active',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'inactive', nlabel => 'fcports.inactive.count', set => {
                key_values => [ { name => 'inactive' } ],
                output_template => '%s inactive',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'host-logins', nlabel => 'fcports.host.logins.count', set => {
                key_values => [ { name => 'host_logins' } ],
                output_template => '%s host login(s)',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{ports} = [
        {
            label => 'status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{status} !~ /^(active|inactive_configured|inactive_unconfigured)$/i',
            warning_default => '%{status} =~ /^inactive_configured$/i and %{attachment} =~ /^switch$/i',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'status' }, { name => 'port_speed' },
                    { name => 'attachment' }, { name => 'node_name' }, { name => 'port_id' },
                    { name => 'type' }, { name => 'active_login_count' }
                ],
                closure_custom_output => $self->can('custom_port_output'),
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
        'include-name:s' => { name => 'include_name' },
        'exclude-name:s' => { name => 'exclude_name' },
        'include-type:s' => { name => 'include_type' },
        'exclude-type:s' => { name => 'exclude_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # Host logins are read on the virtual (NPIV) target ports, keyed on
    # fc_io_port_id, then summed per physical port.
    my %logins;
    foreach my $target (@{$options{custom}->request_optional(command => 'lstargetportfc')}) {
        my $count = $target->{active_login_count};
        next if (is_empty($target->{fc_io_port_id}) || !defined($count) || $count !~ /^\d+$/);
        $logins{$target->{fc_io_port_id}} += $count;
    }

    $self->{global} = { detected => 0, active => 0, inactive => 0, host_logins => 0 };
    $self->{ports} = {};

    foreach my $port (@{$options{custom}->request(command => 'lsportfc')}) {
        my $name = ($port->{node_name} // '') . '-' . ($port->{port_id} // '');
        my $type = $port->{type} // '';

        next if (is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}));
        next if (is_excluded($type, $self->{option_results}->{include_type}, $self->{option_results}->{exclude_type}));

        my $status = $port->{status} // '';
        my $login_count = $logins{$port->{fc_io_port_id} // ''} // '';

        $self->{global}->{detected}++;
        if ($status =~ /^active$/i) {
            $self->{global}->{active}++;
        } else {
            $self->{global}->{inactive}++;
        }
        $self->{global}->{host_logins} += $login_count if (is_not_empty($login_count));

        $self->{ports}->{$name} = {
            name => $name,
            status => $status,
            port_speed => $port->{port_speed} // '',
            attachment => $port->{attachment} // '',
            node_name => $port->{node_name} // '',
            port_id => $port->{port_id} // '',
            type => $type,
            active_login_count => $login_count
        };
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'node_name', 'port_id', 'type', 'status', 'attachment']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(custom => $options{custom});
    foreach my $name (sort keys %{$self->{ports}}) {
        $self->{output}->add_disco_entry(
            name => $self->{ports}->{$name}->{name},
            node_name => $self->{ports}->{$name}->{node_name},
            port_id => $self->{ports}->{$name}->{port_id},
            type => $self->{ports}->{$name}->{type},
            status => $self->{ports}->{$name}->{status},
            attachment => $self->{ports}->{$name}->{attachment}
        );
    }
}

1;

__END__

=head1 MODE

Check the Fibre Channel ports, the data path, which the C<hardware> mode does
not cover.

This mode also supports service discovery (C<--disco-format>, C<--disco-show>).

C<lsportfc> exposes neither error counters nor throughput: status, negotiated
speed and attachment are all there is. Throughput is only available per node,
through C<lsnodecanisterstats>.

Host logins come from C<lstargetportfc>, aggregated per physical port. An active
port that loses its logins is a lost path, and nothing else would show it.

Ports are named after their node and port number, C<node1-1>, because port ids
are not contiguous (0 to 3 then 24 to 27 on a two-canister system), so a service
called "Port 24" would help nobody.

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=fc-ports --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx --insecure

=over 8

=item B<--include-name>

Filter ports by C<node-port> name (can be a regexp).

=item B<--exclude-name>

Exclude ports by C<node-port> name (can be a regexp).

=item B<--include-type>

Filter ports by type (can be a regexp), for example C<fc> or C<ethernet>.

=item B<--exclude-type>

Exclude ports by type (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.

Threshold on each port. Available macros: C<name>, C<status>, C<port_speed>,
C<attachment>, C<node_name>, C<port_id>, C<type>, C<active_login_count>.

A port fitted with an SFP but cabled to nothing reports C<inactive_configured>
permanently, by IBM design, and no option changes that. Treating it as a fault
would make the service critical forever, which teaches people to ignore it. The
defaults therefore only warn when such a port claims to be attached to a switch,
and only alert on states that mean something actually degraded.

To require a negotiated speed, add it explicitly:

    --critical-status='%{status} !~ /^active$/i || %{port_speed} !~ /^16Gb$/'

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.

Threshold on each port. Available macros: C<name>, C<status>, C<port_speed>,
C<attachment>, C<node_name>, C<port_id>, C<type>, C<active_login_count>.

Default warning: C<%{status} =~ /^inactive_configured$/i and %{attachment} =~ /^switch$/i>.

A port fitted with an SFP but cabled to nothing reports C<inactive_configured>
permanently, by IBM design, and no option changes that. Treating it as a fault
would make the service critical forever, which teaches people to ignore it. The
defaults therefore only warn when such a port claims to be attached to a switch,
and only alert on states that mean something actually degraded.

To require a negotiated speed, add it explicitly:

    --critical-status='%{status} !~ /^active$/i || %{port_speed} !~ /^16Gb$/'

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.

Threshold on each port. Available macros: C<name>, C<status>, C<port_speed>,
C<attachment>, C<node_name>, C<port_id>, C<type>, C<active_login_count>.

Default critical: C<%{status} !~ /^(active|inactive_configured|inactive_unconfigured)$/i>.

A port fitted with an SFP but cabled to nothing reports C<inactive_configured>
permanently, by IBM design, and no option changes that. Treating it as a fault
would make the service critical forever, which teaches people to ignore it. The
defaults therefore only warn when such a port claims to be attached to a switch,
and only alert on states that mean something actually degraded.

To require a negotiated speed, add it explicitly:

    --critical-status='%{status} !~ /^active$/i || %{port_speed} !~ /^16Gb$/'

=item B<--warning-active>

Warning threshold.

Thresholds on the number of active and inactive ports.

=item B<--critical-active>

Critical threshold.

Thresholds on the number of active and inactive ports.

=item B<--warning-inactive>

Warning threshold.

Thresholds on the number of active and inactive ports.

=item B<--critical-inactive>

Critical threshold.

Thresholds on the number of active and inactive ports.

=item B<--warning-host-logins>

Warning threshold.

Threshold on the total number of host logins across all ports. Useful to catch
a fabric-wide loss that leaves every port nominally active.

=item B<--critical-host-logins>

Critical threshold.

Threshold on the total number of host logins across all ports. Useful to catch
a fabric-wide loss that leaves every port nominally active.

=back

=cut
