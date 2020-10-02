#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::paloalto::ssh::mode::ipsec;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [monitor status: %s][ike phase1 state: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{monitor_status},
        $self->{result_values}->{ike_phase1_state}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'tunnels', type => 1, cb_prefix_output => 'prefix_ipsec_output',  message_multiple => 'All ipsec tunnels are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'ipsec-total', nlabel => 'tunnels.ipsec.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total_ipsec' } ],
                output_template => 'total ipsec tunnels: %s',
                perfdatas => [
                    { value => 'total_ipsec', template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{tunnels} = [
        { label => 'status', type => 2, critical_default => '%{ike_phase1_state} eq "down" or %{state} ne "active"', set => {
                key_values => [
                    { name => 'state' }, { name => 'ike_phase1_state' },
                    { name => 'monitor_status' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub prefix_ipsec_output {
    my ($self, %options) = @_;

    return "Tunnel ipsec '" . $options{instance_value}->{display} . "' ";
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

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->execute_command(command => 'show vpn ike-sa', ForceArray => ['entry']);

    $self->{global} = { total_ipsec => 0 };
    $self->{tunnels} = {};
    foreach (@{$result->{entry}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
           $_->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{tunnels}->{ $_->{gwid} } = {
            display => $_->{name},
            ike_phase1_state => defined($_->{created}) && $_->{created} ne '' ? 'up' : 'down',
            monitor_status => 'unknown', # could be 'up', 'down', 'off'
            state => 'unknown'
        };

        $self->{global}->{total_ipsec}++;
    }

    return if ($self->{global}->{total_ipsec} == 0);

    $result = $options{custom}->execute_command(command => 'show vpn ipsec-sa', ForceArray => ['entry']);
    foreach (@{$result->{entries}->{entry}}) {
        if (defined($self->{tunnels}->{$_->{gwid}})) {
            $self->{tunnels}->{$_->{gwid}}->{tid} = $_->{tid};
        }
    }

    $result = $options{custom}->execute_command(command => 'show vpn flow', ForceArray => ['entry']);
    foreach my $gwid (keys %{$self->{tunnels}}) {
        next if (!defined($self->{tunnels}->{$gwid}->{tid}));
        foreach (@{$result->{IPSec}->{entry}}) {
            next if ($self->{tunnels}->{$gwid}->{tid} ne $_->{id});
            $self->{tunnels}->{ $_->{gwid} }->{state} = $_->{state};
            $self->{tunnels}->{ $_->{gwid} }->{monitor_status} = $_->{mon};
        }
    }
}

1;

__END__

=head1 MODE

Check ipsec tunnels.

=over 8

=item B<--filter-name>

Filter tunnels by name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{ike_phase1_state}, %{state}, %{monitor_status}, %{display}.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{ike_phase1_state}, %{state}, %{monitor_status}, %{display}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{ike_phase1_state} eq "down" or %{state} ne "active"').
Can used special variables like: %{ike_phase1_state}, %{state}, %{monitor_status}, %{display}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'ipsec-total'.

=back

=cut
