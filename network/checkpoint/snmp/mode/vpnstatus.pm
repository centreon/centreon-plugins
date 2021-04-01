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

package network::checkpoint::snmp::mode::vpnstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status : ' . $self->{result_values}->{status};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'vpn', type => 1, cb_prefix_output => 'prefix_vpn_output', message_multiple => 'All vpn are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'tunnels-total', nlabel => 'vpn.tunnels.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'current total number of tunnels: %d',
                perfdatas => [
                    { value => 'total', template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vpn} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'type' }, { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
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
        'critical-status:s' => { name => 'critical_status', default => '%{type} eq "permanent" and %{status} =~ /down/i' },
        'filter-name:s'     => { name => 'filter_name' },
        'buggy-snmp'        => { name => 'buggy_snmp' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_vpn_output {
    my ($self, %options) = @_;

    return "VPN '" . $options{instance_value}->{display} . "' ";
}

my $map_type = { 1 => 'regular', 2 => 'permanent' };
my $map_state = {
    3 => 'active', 4 => 'destroy', 129 => 'idle', 130 => 'phase1',
    131 => 'down', 132 => 'init'
};

my $mapping = {
    tunnelPeerObjName   => { oid => '.1.3.6.1.4.1.2620.500.9002.1.2' },
    tunnelState         => { oid => '.1.3.6.1.4.1.2620.500.9002.1.3', map => $map_state },
    tunnelType          => { oid => '.1.3.6.1.4.1.2620.500.9002.1.11', map => $map_type }
};
my $oid_tunnelEntry = '.1.3.6.1.4.1.2620.500.9002.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result;
    if (defined($self->{option_results}->{buggy_snmp})) {
        $snmp_result = $options{snmp}->get_table(oid => $oid_tunnelEntry, nothing_quit => 1);
    } else {
        $snmp_result = $options{snmp}->get_multiple_table(
            oids => [
                { oid => $oid_tunnelEntry, start => $mapping->{tunnelPeerObjName}->{oid}, end => $mapping->{tunnelState}->{oid}  },
                { oid => $mapping->{tunnelType}->{oid} }
            ],
            nothing_quit => 1,
            return_type => 1
        );
    }

    $self->{global} = { total => 0 };
    $self->{vs} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{tunnelState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{tunnelPeerObjName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{tunnelPeerObjName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{vpn}->{$instance} = {
            display => $result->{tunnelPeerObjName}, 
            status => $result->{tunnelState},
            type => $result->{tunnelType}
        };
        $self->{global}->{total}++;
    }

    if (scalar(keys %{$self->{vpn}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No vpn found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check vpn status.

=over 8

=item B<--filter-name>

Filter vpn name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{type}, %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{type} eq "permanent" and %{status} =~ /down/i').
Can used special variables like: %{type}, %{status}, %{display}

=item B<--buggy-snmp>

Checkpoint snmp can be buggy. Test that option if no response.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'tunnels-total'.

=back

=cut
