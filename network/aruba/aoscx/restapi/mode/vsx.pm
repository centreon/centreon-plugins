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

package network::aruba::aoscx::restapi::mode::vsx;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_device_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'role: %s [config sync: %s]',
        $self->{result_values}->{role},
        $self->{result_values}->{config_sync}
    );
}

sub custom_isl_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{isl_status}
    );
}

sub custom_keepalive_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{keepalive_status}
    );
}

sub vsx_long_output {
    my ($self, %options) = @_;

    return 'checking virtual switching extension';
}

sub prefix_vsx_output {
    my ($self, %options) = @_;

    return 'Virtual switching extension ';
}

sub prefix_isl_output {
    my ($self, %options) = @_;

    return 'inter-switch link ';
}

sub prefix_keepalive_output {
    my ($self, %options) = @_;

    return 'keepalive ';
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return 'device ';
}

sub set_counters {
    my ($self, %options) = @_;

     $self->{maps_counters_type} = [
        { name => 'vsx', type => 3, cb_prefix_output => 'prefix_vsx_output', cb_long_output => 'vsx_long_output', indent_long_output => '    ',
            group => [
                { name => 'device', type => 0, display_short => 0, cb_prefix_output => 'prefix_device_output', skipped_code => { -10 => 1 } },
                { name => 'isl', type => 0, display_short => 0, cb_prefix_output => 'prefix_isl_output', skipped_code => { -10 => 1 } },
                { name => 'keepalive', type => 0, display_short => 0, cb_prefix_output => 'prefix_keepalive_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{device} = [
        {
            label => 'device-status',
            type => 2,
            set => {
                key_values => [ { name => 'role' }, { name => 'config_sync' } ],
                closure_custom_output => $self->can('custom_device_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{isl} = [
        {
            label => 'isl-status',
            type => 2,
            critical_default => '%{isl_status} =~ /out_sync/',
            set => {
                key_values => [ { name => 'isl_status' } ],
                closure_custom_output => $self->can('custom_isl_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'isl-packets-in', nlabel => 'vsx.isl.packets.in.count', set => {
                key_values => [ { name => 'isl_packets_in', diff => 1 } ],
                output_template => 'packets in: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'isl-packets-out', nlabel => 'vsx.isl.packets.out.count', set => {
                key_values => [ { name => 'isl_packets_in', diff => 1 } ],
                output_template => 'packets out: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{keepalive} = [
        {
            label => 'keepalive-status',
            type => 2,
            critical_default => '%{keepalive_status} =~ /out_of_sync_established|failed/',
            set => {
                key_values => [ { name => 'keepalive_status' } ],
                closure_custom_output => $self->can('custom_keepalive_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'keepalive-packets-in', nlabel => 'vsx.keepalive.packets.in.count', set => {
                key_values => [ { name => 'keepalive_packets_in', diff => 1 } ],
                output_template => 'packets in: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'keepalive-packets-out', nlabel => 'vsx.keepalive.packets.out.count', set => {
                key_values => [ { name => 'keepalive_packets_in', diff => 1 } ],
                output_template => 'packets out: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $vsx = $options{custom}->request(endpoint => '/system/vsx');

    $self->{output}->output_add(short_msg => 'virtual switching extension is ok');

    $self->{vsx} = {
        global => {
            device => {
                role => $vsx->{device_role},
                config_sync => $vsx->{config_sync_disable} =~ /False|1/ ? 'disabled' : 'enabled'
            },
            isl => {
                isl_status => $vsx->{oper_status}->{islp_link_state},
                isl_packets_out => $vsx->{isl_statistics}->{pdu_tx},
                isl_packets_in => $vsx->{isl_statistics}->{pdu_rx}
            },
            keepalive => {
                keepalive_status => $vsx->{keepalive_status}->{state},
                keepalive_packets_out => $vsx->{keepalive_statistics}->{tx},
                keepalive_packets_in => $vsx->{keepalive_statistics}->{rx}
            }
        }
    };

    $self->{cache_name} = 'aruba_aoscx_' . $self->{mode} . '_' . $options{custom}->get_connection_infos() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check virtual switching extension.

=over 8

=item B<--unknown-device-status>

Set unknown threshold for status.
Can used special variables like: %{role}, %{config_sync}

=item B<--warning-device-status>

Set warning threshold for status.
Can used special variables like: %{role}, %{config_sync}

=item B<--critical-device-status>

Set critical threshold for status.
Can used special variables like: %{role}, %{config_sync}

=item B<--unknown-isl-status>

Set unknown threshold for status.
Can used special variables like: %{isl_status}

=item B<--warning-isl-status>

Set warning threshold for status.
Can used special variables like: %{isl_status}

=item B<--critical-isl-status>

Set critical threshold for status (Default: '%{isl_status} =~ /out_sync/').
Can used special variables like: %{isl_status}

=item B<--unknown-keepalive-status>

Set unknown threshold for status.
Can used special variables like: %{keepalive_status}

=item B<--warning-keepalive-status>

Set warning threshold for status.
Can used special variables like: %{keepalive_status}

=item B<--critical-keepalive-status>

Set critical threshold for status (Default: '%{keepalive_status} =~ /out_of_sync_established|failed/').
Can used special variables like: %{keepalive_status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'isl-packets-in', 'isl-packets-out', 'keepalive-packets-in', 'keepalive-packets-out'.

=back

=cut
