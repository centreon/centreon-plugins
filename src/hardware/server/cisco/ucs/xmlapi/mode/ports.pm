#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package hardware::server::cisco::ucs::xmlapi::mode::ports;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf(
        "port '%s' [role: %s] [speed: %s] oper state is '%s'",
        $self->{result_values}->{display},
        $self->{result_values}->{role},
        $self->{result_values}->{speed},
        $self->{result_values}->{oper_state}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'ports',  type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All ports are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total',    nlabel => 'ports.total.count',    set => {
            key_values      => [ { name => 'total' } ],
            output_template => 'Total: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
        { label => 'up',       nlabel => 'ports.up.count',       set => {
            key_values      => [ { name => 'up' } ],
            output_template => 'Up: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
        { label => 'down',     nlabel => 'ports.down.count',     set => {
            key_values      => [ { name => 'down' } ],
            output_template => 'Down: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
        { label => 'sfp-not-present', nlabel => 'ports.sfpnotpresent.count', set => {
            key_values      => [ { name => 'sfpnotpresent' } ],
            output_template => 'SFP not present: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
    ];

    $self->{maps_counters}->{ports} = [
        { label => 'status', type => 2,
          set => {
            key_values => [
                { name => 'display' }, { name => 'oper_state' },
                { name => 'role' },    { name => 'speed' },
                { name => 'admin_state' },
            ],
            closure_custom_output           => $self->can('custom_status_output'),
            closure_custom_perfdata         => sub { return 0; },
            closure_custom_threshold_check => \&_threshold_check,
          }
        },
    ];
}

sub _threshold_check {
    my ($self, %options) = @_;

    my $oper  = $self->{result_values}->{oper_state};
    my $admin = $self->{result_values}->{admin_state};

    if (defined($self->{instance_mode}->{option_results}->{critical_status})
        && $self->{instance_mode}->{option_results}->{critical_status} ne '') {
        my $display = $self->{result_values}->{display};
        my $role    = $self->{result_values}->{role};
        ## no critic
        return 'CRITICAL' if eval "$self->{instance_mode}->{option_results}->{critical_status}";
    }
    if (defined($self->{instance_mode}->{option_results}->{warning_status})
        && $self->{instance_mode}->{option_results}->{warning_status} ne '') {
        my $display = $self->{result_values}->{display};
        my $role    = $self->{result_values}->{role};
        return 'WARNING' if eval "$self->{instance_mode}->{option_results}->{warning_status}";
    }
    return 'OK';
}

sub prefix_output {
    my ($self, %options) = @_;
    return "Port '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-port:s'      => { name => 'filter_port' },
        'filter-role:s'      => { name => 'filter_role' },
        'filter-fi:s'        => { name => 'filter_fi' },
        'skip-admin-down'    => { name => 'skip_admin_down' },
        'warning-status:s'   => { name => 'warning_status',  default => '' },
        'critical-status:s'  => { name => 'critical_status',
            default => '%{oper_state} =~ /^down$/i && %{admin_state} =~ /^enabled$/i' },
    });

    return $self;
}

# Map oper state to counter bucket
my %oper_state_map = (
    up              => 'up',
    down            => 'down',
    'sfp-not-present' => 'sfpnotpresent',
    'sfpNotPresent' => 'sfpnotpresent',
);

sub manage_selection {
    my ($self, %options) = @_;

    my $ports = $options{custom}->request(class_id => 'etherPIo');

    $self->{global} = { total => 0, up => 0, down => 0, sfpnotpresent => 0 };
    $self->{ports}  = {};

    foreach my $port (@{$ports}) {
        my $dn         = $port->{dn}         // '';
        my $role       = $port->{ifRole}     // 'unknown';
        my $oper_state = $port->{operState}  // 'unknown';
        my $admin_state = $port->{adminState} // 'unknown';
        my $speed      = $port->{operSpeed}  // 'unknown';
        my $port_id    = $port->{portId}     // '';
        my $slot_id    = $port->{slotId}     // '';

        # Build a readable display name from DN
        # e.g. sys/switch-A/slot-1/switch-ether/port-3 -> FI-A/slot-1/port-3
        (my $display = $dn) =~ s{sys/switch-}{FI-};
        $display =~ s{/switch-ether}{};
        $display =~ s{/switch-fc}{};

        next if defined($self->{option_results}->{filter_fi})
            && $self->{option_results}->{filter_fi} ne ''
            && $display !~ /$self->{option_results}->{filter_fi}/;

        next if defined($self->{option_results}->{filter_role})
            && $self->{option_results}->{filter_role} ne ''
            && $role !~ /$self->{option_results}->{filter_role}/;

        next if defined($self->{option_results}->{filter_port})
            && $self->{option_results}->{filter_port} ne ''
            && $display !~ /$self->{option_results}->{filter_port}/;

        next if defined($self->{option_results}->{skip_admin_down})
            && $admin_state =~ /^disabled$/i;

        $self->{global}->{total}++;
        my $bucket = $oper_state_map{ lc($oper_state) } // 'down';
        $self->{global}->{$bucket}++ if exists $self->{global}->{$bucket};

        $self->{ports}->{$dn} = {
            display     => $display,
            oper_state  => $oper_state,
            admin_state => $admin_state,
            role        => $role,
            speed       => $speed,
        };
    }
}

1;

__END__

=head1 MODE

Check Cisco UCS Ethernet port status via XML API (etherPIo class).

=over 8

=item B<--filter-port>

Filter ports by display name (regexp). Example: --filter-port='FI-A'

=item B<--filter-role>

Filter ports by role (regexp): serverPort, uplinkPort, networkFCOEPort, storagePort.
Example: --filter-role='uplinkPort'

=item B<--filter-fi>

Filter by FI (regexp). Example: --filter-fi='FI-A'

=item B<--skip-admin-down>

Skip ports that are administratively disabled.

=item B<--warning-status>

Warning threshold. Perl expression using %{oper_state}, %{admin_state}, %{role}.

=item B<--critical-status>

Critical threshold (default: '%{oper_state} =~ /^down$/i && %{admin_state} =~ /^enabled$/i').

=back

=cut
