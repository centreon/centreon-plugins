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

package network::fritzbox::upnp::mode::traffic;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    my ($warning, $critical);
    if ($self->{instance_mode}->{option_results}->{unit} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{speed}, cast_int => 1);
    } elsif ($self->{instance_mode}->{option_results}->{unit} =~ /bps|counter/) {
        $warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel});
        $critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel});
    }

    if ($self->{instance_mode}->{option_results}->{unit} eq 'counter') {
        my $nlabel = $self->{nlabel};
        $nlabel =~ s/bitspersecond/bits/;
        $self->{output}->perfdata_add(
            nlabel => $nlabel,
            unit => 'b',
            value => $self->{result_values}->{traffic_counter},
            warning => $warning,
            critical => $critical,
            min => 0
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            unit => 'b/s',
            value => sprintf('%.2f', $self->{result_values}->{traffic_per_seconds}),
            warning => $warning,
            critical => $critical,
            min => 0, max => $self->{result_values}->{speed}
        );
    }
}

sub custom_traffic_threshold {
    my ($self, %options) = @_;

    my $exit = 'ok';
    if ($self->{instance_mode}->{option_results}->{unit} eq 'percent_delta' && defined($self->{result_values}->{speed})) {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_prct}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{unit} eq 'bps') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_per_seconds}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    } elsif ($self->{instance_mode}->{option_results}->{unit} eq 'counter') {
        $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{traffic_counter}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    }
    return $exit;
}

sub custom_traffic_output {
    my ($self, %options) = @_;

    my ($traffic_value, $traffic_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{traffic_per_seconds}, network => 1);
    return sprintf(
        'Traffic %s: %s/s (%s)',
        ucfirst($self->{result_values}->{label}), $traffic_value . $traffic_unit,
        defined($self->{result_values}->{traffic_prct}) ? sprintf('%.2f%%', $self->{result_values}->{traffic_prct}) : '-'
    );
}

sub custom_traffic_calc {
    my ($self, %options) = @_;

    my $diff_traffic = ($options{new_datas}->{ $self->{instance} . '_total_' . $options{extra_options}->{label_ref} } - $options{old_datas}->{ $self->{instance} . '_total_' . $options{extra_options}->{label_ref} });
    $self->{result_values}->{traffic_per_seconds} = $diff_traffic / $options{delta_time};
    $self->{result_values}->{traffic_counter} = $options{new_datas}->{ $self->{instance} . '_total_' . $options{extra_options}->{label_ref} };
    if (defined($options{new_datas}->{$self->{instance} . '_max_' . $options{extra_options}->{label_ref}}) &&
        $options{new_datas}->{$self->{instance} . '_max_' . $options{extra_options}->{label_ref}} > 0) {
        $self->{result_values}->{traffic_prct} = $self->{result_values}->{traffic_per_seconds} * 100 / $options{new_datas}->{$self->{instance} . '_max_' . $options{extra_options}->{label_ref}};
        $self->{result_values}->{speed} = $options{new_datas}->{$self->{instance} . '_max_' . $options{extra_options}->{label_ref}};
    }

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'traffic-in', nlabel => 'system.interface.wan.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'total_in', diff => 1 }, { name => 'max_in'} ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'in' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic In : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        },
        { label => 'traffic-out', nlabel => 'system.interface.wan.traffic.out.bitspersecond', set => {
                key_values =>  [ { name => 'total_out', diff => 1 }, { name => 'max_out'} ],
                closure_custom_calc => $self->can('custom_traffic_calc'), closure_custom_calc_extra_options => { label_ref => 'out' },
                closure_custom_output => $self->can('custom_traffic_output'), output_error_template => 'Traffic Out : %s',
                closure_custom_perfdata => $self->can('custom_traffic_perfdata'),
                closure_custom_threshold_check => $self->can('custom_traffic_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'unit:s' => { name => 'unit', default => 'percent_delta' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{unit} = 'percent_delta'
        if (!defined($self->{option_results}->{unit}) ||
            $self->{option_results}->{unit} eq '' ||
            $self->{option_results}->{unit} eq '%');
    if ($self->{option_results}->{unit} !~ /^(?:percent_delta|bps|counter)$/) {
        $self->{output}->add_option_msg(short_msg => 'Wrong option --unit');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'fritzbox_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' . $options{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    $self->{global} = {};

=pod
<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<s:Body>
<u:GetAddonInfosResponse xmlns:u="urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1">
<NewByteSendRate>6686</NewByteSendRate>  <--- upload
<NewByteReceiveRate>1414078</NewByteReceiveRate>  <--- download
<NewPacketSendRate>0</NewPacketSendRate>
<NewPacketReceiveRate>0</NewPacketReceiveRate>
<NewTotalBytesSent>819115474</NewTotalBytesSent>
<NewTotalBytesReceived>2080148768</NewTotalBytesReceived>
<NewAutoDisconnectTime>0</NewAutoDisconnectTime>
<NewIdleDisconnectTime>0</NewIdleDisconnectTime>
<NewDNSServer1>83.169.185.161</NewDNSServer1>
<NewDNSServer2>83.169.185.225</NewDNSServer2>
<NewVoipDNSServer1>83.169.185.132</NewVoipDNSServer1>
<NewVoipDNSServer2>83.169.185.127</NewVoipDNSServer2>
<NewUpnpControlEnabled>1</NewUpnpControlEnabled>
<NewRoutedBridgedModeBoth>1</NewRoutedBridgedModeBoth>
<NewX_AVM_DE_TotalBytesSent64>819115474</NewX_AVM_DE_TotalBytesSent64>
<NewX_AVM_DE_TotalBytesReceived64>2080148768</NewX_AVM_DE_TotalBytesReceived64>
<NewX_AVM_DE_WANAccessType>Cable</NewX_AVM_DE_WANAccessType>
</u:GetAddonInfosResponse>
</s:Body>
=cut
    my $infos = $options{custom}->request(url => 'WANCommonIFC1', ns => 'WANCommonInterfaceConfig', verb => 'GetAddonInfos');
    $self->{global}->{total_out} = $infos->{'s:Body'}->{'u:GetAddonInfosResponse'}->{NewTotalBytesSent} * 8;
    $self->{global}->{total_in} = $infos->{'s:Body'}->{'u:GetAddonInfosResponse'}->{NewTotalBytesReceived} * 8;

    $infos = $options{custom}->request(url => 'WANCommonIFC1', ns => 'WANCommonInterfaceConfig', verb => 'GetCommonLinkProperties');
    $self->{global}->{max_out} = $infos->{'s:Body'}->{'u:GetCommonLinkPropertiesResponse'}->{NewLayer1UpstreamMaxBitRate};
    $self->{global}->{max_in} = $infos->{'s:Body'}->{'u:GetCommonLinkPropertiesResponse'}->{NewLayer1DownstreamMaxBitRate};
}

1;

__END__

=head1 MODE

Checks your FritzBox traffic on WAN interface.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^connections$'

=item B<--unit>

Unit of thresholds for the traffic (default: 'percent_delta') ('percent_delta', 'bps', 'counter').

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'traffic-in', 'traffic-out'.

=back

=cut
