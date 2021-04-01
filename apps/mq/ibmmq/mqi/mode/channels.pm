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

package apps::mq::ibmmq::mqi::mode::channels;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [message channel agent: %s]',
        $self->{result_values}->{channel_status},
        $self->{result_values}->{mca_status}
    );
}

sub custom_traffic_in_perfdata {
    my ($self) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel}, unit => 'b/s',
        instances => [$self->{result_values}->{qmgr_name}, $self->{result_values}->{channel_name}],
        value => $self->{result_values}->{traffic_in},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_traffic_out_perfdata {
    my ($self) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel}, unit => 'b/s',
        instances => [$self->{result_values}->{qmgr_name}, $self->{result_values}->{channel_name}],
        value => $self->{result_values}->{traffic_out},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub prefix_channel_output {
    my ($self, %options) = @_;

    return "Channel '" . $options{instance_value}->{qmgr_name} . ':' . $options{instance_value}->{channel_name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'channel', type => 1, cb_prefix_output => 'prefix_channel_output', message_multiple => 'All channels are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{channel} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'qmgr_name' }, { name => 'channel_name' },
                    { name => 'channel_status' }, { name => 'mca_status' }
                ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'traffic-in', nlabel => 'channel.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'qmgr_name' }, { name => 'channel_name' } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => $self->can('custom_traffic_in_perfdata')
            }
        },
        { label => 'traffic-out', nlabel => 'channel.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'qmgr_name' }, { name => 'channel_name' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => $self->can('custom_traffic_out_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'filter-type:s'     => { name => 'filter_type' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{channel_status} !~ /running|idle/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->execute_command(
        command => 'InquireChannelStatus',
        attrs => { }
    );
    my $names = $options{custom}->execute_command(
        command => 'InquireChannel',
        attrs => { }
    );

    $self->{channel} = {};
    foreach (@$result) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' 
            && $_->{ChannelName} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' 
            && $_->{ChannelType} !~ /$self->{option_results}->{filter_type}/);

        $self->{channel}->{$_->{ChannelName}} = {
            qmgr_name => $options{custom}->get_qmgr_name(),
            channel_name => $_->{ChannelName},
            channel_status => lc($_->{ChannelStatus}),
            channel_type => $_->{ChannelType},
            mca_status => lc($_->{MCAStatus}),
            traffic_in => $_->{BytesReceived} * 8,
            traffic_out => $_->{BytesSent} * 8
        };
    }

    foreach (@$names) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' 
            && $_->{ChannelName} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' 
            && $_->{ChannelType} !~ /$self->{option_results}->{filter_type}/i);
    
        if (!defined($self->{channel}->{$_->{ChannelName}})) {
            $self->{channel}->{$_->{ChannelName}} = {
                qmgr_name => $options{custom}->get_qmgr_name(),
                channel_name => $_->{ChannelName},
                channel_status => 'idle',
                channel_type => $_->{ChannelType},
                mca_status => '-',
            };
        }
    }

    $self->{cache_name} = 'ibmmq_' . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check channels.

=over 8

=item B<--filter-name>

Filter channel name (Can use regexp).

=item B<--filter-type>

Filter channel type (Can use regexp, insensitive search).

Here is the IBM - Perl mapping about Channel types: 

SDR - Sender
SVR - Server
RCVR - Receiver
RQSTR - Requester
CLNTCONN - Clntconn
SVRCONN - Svrconn
CLUSSDR - ClusterSender
CLUSRCVR - ClusterReceiver
MQTT - Telemetry

=item B<--unknown-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{channel_status}, %{mca_status}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{channel_status}, %{mca_status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{channel_status} !~ /running|idle/i').
Can used special variables like: %{channel_status}, %{mca_status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'traffic-in', 'traffic-out'.

=back

=cut
