#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::juniper::common::junos::netconf::mode::ldp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_ldp_perfdata {
    my ($self) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        my $value;
        if ($_ eq 'messageType') {
            $value = $self->{key_values}->[0]->{name};
            $value =~ s/_/ /g;
        } else {
            $value = $self->{result_values}->{$_};
        }
        push @$instances, $value;
    }

    $self->{output}->perfdata_add(
        nlabel    => $self->{nlabel},
        instances => $instances,
        value     => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min       => 0
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'connection state: %s, session state: %s',
        $self->{result_values}->{connectionState},
        $self->{result_values}->{sessionState}
    );
}

sub ldp_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking LDP session '%s'",
        $options{instance_value}->{remoteAddress}
    );
}

sub prefix_ldp_output {
    my ($self, %options) = @_;

    return sprintf(
        "LDP session '%s' ",
        $options{instance_value}->{remoteAddress}
    );
}

sub prefix_messages_sent_output {
    my ($self, %options) = @_;

    return 'messages sent ';
}

sub prefix_messages_received_output {
    my ($self, %options) = @_;

    return 'messages received ';
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of LDP sessions ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name               => 'ldp', type => 3, cb_prefix_output => 'prefix_ldp_output', cb_long_output => 'ldp_long_output',
          indent_long_output => '    ', message_multiple => 'All LDP sessions are ok',
          group              => [
              { name => 'status', type => 0, skipped_code => { -10 => 1 } },
              { name => 'messages_sent', type => 0, cb_prefix_output => 'prefix_messages_sent_output', skipped_code => { -10 => 1 } },
              { name => 'messages_received', type => 0, cb_prefix_output => 'prefix_messages_received_output', skipped_code => { -10 => 1 } }
          ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'ldp-sessions-detected', display_ok => 0, nlabel => 'ldp.sessions.detected.count', set => {
            key_values      => [ { name => 'detected' } ],
            output_template => 'detected: %s',
            perfdatas       => [
                { template => '%s', min => 0 }
            ]
        }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{connectionState} !~ /open$/i || %{sessionState} !~ /operational/i',
            set              => {
                key_values                     => [
                    { name => 'id' }, { name => 'remoteAddress' }, { name => 'sessionState' }, { name => 'connectionState' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{messages_sent} = [];
    $self->{maps_counters}->{messages_received} = [];
    foreach (('initialization', 'keeaplive', 'notification', 'address', 'address withdraw',
              'label mapping', 'label request', 'label withdraw', 'label release', 'label abort')) {
        my ($label, $nlabel) = ($_, $_);
        $label =~ s/\s+/-/g;
        $nlabel =~ s/\s+/_/g;
        push @{$self->{maps_counters}->{messages_sent}}, {
            label => 'ldp-session-messages-' . $label . '-sent', nlabel => 'ldp.session.messages.sent.count', set => {
            key_values              => [ { name => $nlabel, diff => 1 }, { name => 'id' }, { name => 'remoteAddress' } ],
            output_template         => $_ . ': %s%s',
            closure_custom_perfdata => $self->can('custom_ldp_perfdata')
        }
        };
        push @{$self->{maps_counters}->{messages_received}}, {
            label => 'ldp-session-messages-' . $label . '-received', nlabel => 'ldp.session.messages.received.count', set => {
            key_values              => [ { name => $nlabel, diff => 1 }, { name => 'id' }, { name => 'remoteAddress' } ],
            output_template         => $_ . ': %s%s',
            closure_custom_perfdata => $self->can('custom_ldp_perfdata')
        }
        };
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-id:s'                 => { name => 'filter_id' },
        'filter-remote-address:s'     => { name => 'filter_remote_address' },
        'custom-perfdata-instances:s' => { name => 'custom_perfdata_instances' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{custom_perfdata_instances}) || $self->{option_results}->{custom_perfdata_instances} eq '') {
        $self->{option_results}->{custom_perfdata_instances} = '%(remoteAddress) %(messageType)';
    }

    $self->{custom_perfdata_instances} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances',
        instances   => $self->{option_results}->{custom_perfdata_instances},
        labels      => { id => 1, remoteAddress => 1, messageType => 1 }
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_ldp_infos();

    $self->{global} = { detected => 0 };
    $self->{ldp} = {};
    foreach my $item (@$result) {
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
                 $item->{id} !~ /$self->{option_results}->{filter_id}/);
        next if (defined($self->{option_results}->{filter_remote_address}) && $self->{option_results}->{filter_remote_address} ne '' &&
                 $item->{remoteAddress} !~ /$self->{option_results}->{filter_remote_address}/);

        $self->{ldp}->{ $item->{id} } = {
            remoteAddress     => $item->{remoteAddress},
            status            => {
                id              => $item->{id},
                remoteAddress   => $item->{remoteAddress},
                sessionState    => $item->{sessionState},
                connectionState => $item->{connectionState}
            },
            messages_sent     => {
                id            => $item->{id},
                remoteAddress => $item->{remoteAddress}
            },
            messages_received => {
                id            => $item->{id},
                remoteAddress => $item->{remoteAddress}
            }
        };

        foreach (@{$item->{stats}}) {
            my $type = $_->{messageType};
            $type =~ s/\s+/_/g;
            $self->{ldp}->{ $item->{id} }->{messages_sent}->{$type} = $_->{sent};
            $self->{ldp}->{ $item->{id} }->{messages_received}->{$type} = $_->{received};
        }

        $self->{global}->{detected}++;
    }

    $self->{cache_name} = 'juniper_api_' . $options{custom}->get_identifier() . '_' . $self->{mode} . '_' .
                          md5_hex(
                              (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
                              (defined($self->{option_results}->{filter_id}) ? $self->{option_results}->{filter_id} : '') . '_' .
                              (defined($self->{option_results}->{filter_remote_address}) ? $self->{option_results}->{filter_remote_address} : '')
                          );
}

1;

__END__

=head1 MODE

Check LDP sessions.

=over 8

=item B<--filter-id>

Filter LDP session by ID.

=item B<--filter-remote-address>

Filter LDP session by remote address.

=item B<--custom-perfdata-instances>

Define performance data instances (default: C<%(remoteAddress) %(messageType)>)

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{id}>, C<%{remoteAddress}>, C<%{connectionState}>, C<%{sessionState}>

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{id}>, C<%{remoteAddress}>, C<%{connectionState}>, C<%{sessionState}>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{connectionState} !~ /open$/i || %{sessionState} !~ /operational/i'>).
You can use the following variables: C<%{id}>, C<%{remoteAddress}>, C<%{connectionState}>, C<%{sessionState}>

=item B<--warning-ldp-session-messages-address-received>

Threshold.

=item B<--critical-ldp-session-messages-address-received>

Threshold.

=item B<--warning-ldp-session-messages-address-sent>

Threshold.

=item B<--critical-ldp-session-messages-address-sent>

Threshold.

=item B<--warning-ldp-session-messages-address-withdraw-received>

Threshold.

=item B<--critical-ldp-session-messages-address-withdraw-received>

Threshold.

=item B<--warning-ldp-session-messages-address-withdraw-sent>

Threshold.

=item B<--critical-ldp-session-messages-address-withdraw-sent>

Threshold.

=item B<--warning-ldp-session-messages-initialization-received>

Threshold.

=item B<--critical-ldp-session-messages-initialization-received>

Threshold.

=item B<--warning-ldp-session-messages-initialization-sent>

Threshold.

=item B<--critical-ldp-session-messages-initialization-sent>

Threshold.

=item B<--warning-ldp-session-messages-keeaplive-received>

Threshold.

=item B<--critical-ldp-session-messages-keeaplive-received>

Threshold.

=item B<--warning-ldp-session-messages-keeaplive-sent>

Threshold.

=item B<--critical-ldp-session-messages-keeaplive-sent>

Threshold.

=item B<--warning-ldp-session-messages-label-abort-received>

Threshold.

=item B<--critical-ldp-session-messages-label-abort-received>

Threshold.

=item B<--warning-ldp-session-messages-label-abort-sent>

Threshold.

=item B<--critical-ldp-session-messages-label-abort-sent>

Threshold.

=item B<--warning-ldp-session-messages-label-mapping-received>

Threshold.

=item B<--critical-ldp-session-messages-label-mapping-received>

Threshold.

=item B<--warning-ldp-session-messages-label-mapping-sent>

Threshold.

=item B<--critical-ldp-session-messages-label-mapping-sent>

Threshold.

=item B<--warning-ldp-session-messages-label-release-received>

Threshold.

=item B<--critical-ldp-session-messages-label-release-received>

Threshold.

=item B<--warning-ldp-session-messages-label-release-sent>

Threshold.

=item B<--critical-ldp-session-messages-label-release-sent>

Threshold.

=item B<--warning-ldp-session-messages-label-request-received>

Threshold.

=item B<--critical-ldp-session-messages-label-request-received>

Threshold.

=item B<--warning-ldp-session-messages-label-request-sent>

Threshold.

=item B<--critical-ldp-session-messages-label-request-sent>

Threshold.

=item B<--warning-ldp-session-messages-label-withdraw-received>

Threshold.

=item B<--critical-ldp-session-messages-label-withdraw-received>

Threshold.

=item B<--warning-ldp-session-messages-label-withdraw-sent>

Threshold.

=item B<--critical-ldp-session-messages-label-withdraw-sent>

Threshold.

=item B<--warning-ldp-session-messages-notification-received>

Threshold.

=item B<--critical-ldp-session-messages-notification-received>

Threshold.

=item B<--warning-ldp-session-messages-notification-sent>

Threshold.

=item B<--critical-ldp-session-messages-notification-sent>

Threshold.

=item B<--warning-ldp-sessions-detected>

Threshold.

=item B<--critical-ldp-sessions-detected>

Threshold.

=back

=cut
