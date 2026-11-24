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

package storage::ibm::flashsystem::restapi::mode::ethports;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::misc qw(is_excluded is_not_empty);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_port_output {
    my ($self, %options) = @_;

    my $msg = sprintf('link %s', $self->{result_values}->{link_state});

    $msg .= sprintf(', speed %s', $self->{result_values}->{speed})
        if (is_not_empty($self->{result_values}->{speed}));
    $msg .= sprintf(', roles: %s', $self->{result_values}->{roles})
        if (is_not_empty($self->{result_values}->{roles}));
    $msg .= sprintf(', %s', $self->{result_values}->{ip})
        if (is_not_empty($self->{result_values}->{ip}));

    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Ethernet ports: ' },
        { name => 'ports', type => COUNTER_TYPE_INSTANCE, prefix_output => "Port '%{name}' ",
          message_multiple => 'All Ethernet ports in service are active',
          skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'detected', nlabel => 'ethports.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => '%s detected',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'active', nlabel => 'ethports.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => '%s active',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        # The role flags say what a port is allowed to carry, not what it carries.
        { label => 'with-role', nlabel => 'ethports.withrole.count', set => {
                key_values => [ { name => 'with_role' } ],
                output_template => '%s role-capable',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'ip-configured', nlabel => 'ethports.ip.configured.count', set => {
                key_values => [ { name => 'ip_configured' } ],
                output_template => '%s IP configured',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{ports} = [
        {
            label => 'status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{configured} eq "yes" and %{link_state} !~ /^active$/i',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'link_state' }, { name => 'speed' },
                    { name => 'roles' }, { name => 'ip' }, { name => 'node_name' },
                    { name => 'port_id' }, { name => 'configured' }
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
        'add-unused'     => { name => 'add_unused' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my %addresses;
    my $ip_configured = 0;
    foreach my $entry (@{ $options{custom}->request_optional(command => 'lsportip') }) {
        next unless (ref $entry eq 'HASH');
        next if (($entry->{state} // '') =~ /^unconfigured$/i);
        $ip_configured++;

        my $key = ($entry->{node_name} // '') . '-' . ($entry->{id} // '');
        $addresses{$key} = $entry->{IP_address}
            if (is_not_empty($entry->{IP_address}) && !exists($addresses{$key}));
    }

    $self->{global} = { detected => 0, active => 0, with_role => 0, ip_configured => $ip_configured };
    $self->{ports} = {};

    foreach my $port (@{ $options{custom}->request(command => 'lsportethernet') }) {
        my $name = ($port->{node_name} // '') . '-' . ($port->{port_id} // '');
        next if (is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}));

        my $link = $port->{link_state} // '';

        my @roles = grep { is_not_empty($port->{$_}) && $port->{$_} !~ /^no$/i } qw(management host storage replication);

        $self->{global}->{detected}++;
        $self->{global}->{active}++ if ($link =~ /^active$/i);
        $self->{global}->{with_role}++ if (@roles);

        my $configured = exists($addresses{$name}) ? 'yes' : 'no';
        next if ($configured eq 'no' && $link !~ /^active$/i && !defined($self->{option_results}->{add_unused}));

        $self->{ports}->{$name} = {
            name => $name,
            link_state => $link,
            speed => $port->{speed} // '',
            roles => join('/', @roles),
            ip => $addresses{$name} // '',
            node_name => $port->{node_name} // '',
            port_id => $port->{port_id} // '',
            configured => $configured
        };
    }
}

1;

__END__

=head1 MODE

Check the Ethernet ports and their IP configuration.

Two commands describe two different things, and mixing them up is easy:

=over 4

=item *

C<lsportethernet> is the B<physical> port: link state, negotiated speed,
and the flags saying what it is used for, management, host, storage,
replication.

=item *

C<lsportip> is the IP configuration laid on top. There is one entry per
port B<and per use>, so a single physical port produces several rows, keyed on
C<id> rather than C<port_id>.

=back

On the arrays surveyed, all twelve IP entries are C<unconfigured>, iSCSI is not
used, everything goes over Fibre Channel, and two of the six physical ports are
active at 1 Gb/s.

So an inactive port is B<not> treated as a fault: an unconnected port is a cabling
choice, not a defect, and alerting on it would produce permanent noise.

B<Do not threshold on the role flags.> C<management>, C<host>, C<storage> and
C<replication> report what a port is B<allowed> to carry, not what it currently
carries: an unconnected port has them all set simply because nothing forbids them.
A threshold on "carries a role and link is down" put all four unconnected ports in
permanent CRITICAL. The one reliable sign that a port is in service is an IP
address configured on it, which is what the default threshold uses.

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=eth-ports --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx --insecure

=over 8

=item B<--include-name>

Filter ports by C<node-port> name (can be a regexp).

=item B<--exclude-name>

Exclude ports by C<node-port> name (can be a regexp).

=item B<--add-unused>

Also report ports that carry no role and have no link, the full inventory
rather than just what is in service.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.

Threshold on each port. Available macros: C<name>, C<link_state>, C<speed>,
C<roles>, C<ip>, C<node_name>, C<port_id>, C<configured>.

To also require a negotiated speed on the management ports:

    --warning-status='%{roles} =~ /management/ && %{speed} !~ /^1Gb/'

With no iSCSI in service, no port carries an address and the mode reports the
inventory without ever alerting. That is the intended behaviour: it starts
alerting by itself the day an address is configured.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.

Threshold on each port. Available macros: C<name>, C<link_state>, C<speed>,
C<roles>, C<ip>, C<node_name>, C<port_id>, C<configured>.

To also require a negotiated speed on the management ports:

    --warning-status='%{roles} =~ /management/ && %{speed} !~ /^1Gb/'

With no iSCSI in service, no port carries an address and the mode reports the
inventory without ever alerting. That is the intended behaviour: it starts
alerting by itself the day an address is configured.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.

Threshold on each port. Available macros: C<name>, C<link_state>, C<speed>,
C<roles>, C<ip>, C<node_name>, C<port_id>, C<configured>.

Default critical: C<%{configured} eq "yes" and %{link_state} !~ /^active$/i>.

To also require a negotiated speed on the management ports:

    --warning-status='%{roles} =~ /management/ && %{speed} !~ /^1Gb/'

With no iSCSI in service, no port carries an address and the mode reports the
inventory without ever alerting. That is the intended behaviour: it starts
alerting by itself the day an address is configured.

=item B<--warning-active>

Warning threshold.

Thresholds on the counts. C<ip-configured> is worth watching if iSCSI is ever
put into service: it stays at zero as long as nothing is configured.

=item B<--critical-active>

Critical threshold.

Thresholds on the counts. C<ip-configured> is worth watching if iSCSI is ever
put into service: it stays at zero as long as nothing is configured.

=item B<--warning-with-role>

Warning threshold.

Thresholds on the counts. C<ip-configured> is worth watching if iSCSI is ever
put into service: it stays at zero as long as nothing is configured.

=item B<--critical-with-role>

Critical threshold.

Thresholds on the counts. C<ip-configured> is worth watching if iSCSI is ever
put into service: it stays at zero as long as nothing is configured.

=item B<--warning-ip-configured>

Warning threshold.

Thresholds on the counts. C<ip-configured> is worth watching if iSCSI is ever
put into service: it stays at zero as long as nothing is configured.

=item B<--critical-ip-configured>

Critical threshold.

Thresholds on the counts. C<ip-configured> is worth watching if iSCSI is ever
put into service: it stays at zero as long as nothing is configured.

=back

=cut
