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

package network::paloalto::snmp::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'vsys', type => 1, cb_prefix_output => 'prefix_vsys_output', message_multiple => 'Vsys sessions metrics are OK', skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'active', set => {
                key_values => [ { name => 'panSessionActive' }, { name => 'panSessionMax' } ],
                closure_custom_calc => $self->can('custom_active_calc'),
                closure_custom_output => $self->can('custom_active_output'),
                closure_custom_perfdata => $self->can('custom_active_perfdata'),
                closure_custom_threshold_check => $self->can('custom_active_threshold'),

            }
        },
        { label => 'active-ssl-proxy', nlabel => 'sessions.active.vpnssl.count', set => {
                key_values => [ { name => 'panSessionSslProxyUtilization' } ],
                output_template => 'Active SSL Proxy : %.2f %%',
                perfdatas => [
                    { label => 'active_ssl_proxy', value => 'panSessionSslProxyUtilization_absolute', template => '%.2f', unit => '%',
                      min => 0, max => 100 },
                ],
            }
        },
        { label => 'active-tcp', nlabel => 'sessions.active.tcp.count', set => {
                key_values => [ { name => 'panSessionActiveTcp' } ],
                output_template => 'Active TCP : %s',
                perfdatas => [
                    { label => 'active_tcp', value => 'panSessionActiveTcp_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'active-udp', nlabel => 'sessions.active.udp.count', set => {
                key_values => [ { name => 'panSessionActiveUdp' } ],
                output_template => 'Active UDP : %s',
                perfdatas => [
                    { label => 'active_udp', value => 'panSessionActiveUdp_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'active-icmp', nlabel => 'sessions.active.icmp.count', set => {
                key_values => [ { name => 'panSessionActiveICMP' } ],
                output_template => 'Active ICMP : %s',
                perfdatas => [
                    { label => 'active_icmp', value => 'panSessionActiveICMP_absolute', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{vsys} = [
        { label => 'active-vsys', set => {
                key_values => [ { name => 'panVsysActiveSessions' }, { name => 'panVsysMaxSessions' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_active_calc'),
                closure_custom_output => $self->can('custom_active_output'),
                closure_custom_perfdata => $self->can('custom_active_perfdata'),
                closure_custom_threshold_check => $self->can('custom_active_threshold'),

            }
        },
        { label => 'vsys-active-tcp', nlabel => 'vsys.sessions.active.tcp.count', set => {
                key_values => [ { name => 'panVsysActiveTcpCps' }, { name => 'display' } ],
                output_template => 'Active TCP : %s',
                perfdatas => [
                    { label => 'active_tcp', value => 'panVsysActiveTcpCps_absolute', template => '%s',
                        label_extra_instance => 1, instance_use => 'display_absolute',  min => 0 },
                ],
            }
        },
        { label => 'vsys-active-udp', nlabel => 'vsys.sessions.active.udp.count', set => {
                key_values => [ { name => 'panVsysActiveUdpCps' }, { name => 'display' } ],
                output_template => 'Active UDP : %s',
                perfdatas => [
                    { label => 'active_udp', value => 'panVsysActiveUdpCps_absolute', template => '%s',
                        label_extra_instance => 1, instance_use => 'display_absolute',  min => 0 },
                ],
            }
        },
        { label => 'vsys-active-other', nlabel => 'vsys.sessions.active.other.count', set => {
                key_values => [ { name => 'panVsysActiveOtherIpCps' }, { name => 'display' } ],
                output_template => 'Other : %s',
                perfdatas => [
                    { label => 'active_other', value => 'panVsysActiveOtherIpCps_absolute', template => '%s',
                        label_extra_instance => 1, instance_use => 'display_absolute',  min => 0 },
                ],
            }
        },
    ];



}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Sessions ";
}

sub prefix_vsys_output {
    my ($self, %options) = @_;

    return "Vsys '" . $options{instance_value}->{display} . "' ";

}

sub custom_active_perfdata {
    my ($self, %options) = @_;

    my %total_options = ();

    if ($self->{label} eq 'active') {
        if ($self->{result_values}->{panSessionMax} != 0) {
            $total_options{total} = $self->{result_values}->{panSessionMax};
            $total_options{cast_int} = 1;
        }

        $self->{output}->perfdata_add(label => $self->{label},
                                      nlabel => 'sessions.active.count',
                                      value => $self->{result_values}->{panSessionActive},
                                      warning => defined($total_options{total}) ? $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options) : undef,
                                      critical => defined($total_options{total}) ? $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options) : undef,
                                      min => 0, max => $self->{result_values}->{panSessionMax});
    } else {
        if ($self->{result_values}->{panVsysMaxSessions} != 0) {
            $total_options{total} = $self->{result_values}->{panVsysMaxSessions};
            $total_options{cast_int} = 1;
        }

        $self->{output}->perfdata_add(label => $self->{label},
                                      nlabel => $self->{result_values}->{display} . "#" . 'sessions.active.count',
                                      value => $self->{result_values}->{panVsysActiveSessions},
                                      warning => defined($total_options{total}) ? $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options) : undef,
                                      critical => defined($total_options{total}) ? $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options) : undef,
                                      min => 0, max => $self->{result_values}->{panVsysMaxSessions});
    }
}

sub custom_active_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value) = ('ok');

    if ($self->{label} eq 'active') {
        if ($self->{result_values}->{panSessionMax} != 0) {
            $threshold_value = $self->{result_values}->{active_prct};
        }
        $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold =>
            [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]) if (defined($threshold_value));
        return $exit;
    } else {
        if ($self->{result_values}->{panVsysMaxSessions} != 0) {
            $threshold_value = $self->{result_values}->{active_prct};
        }
        $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold =>
            [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]) if (defined($threshold_value));
        return $exit;
    }
}

sub custom_active_output {
    my ($self, %options) = @_;

    my $msg = "";
    if ($self->{label} eq 'active') {
        $msg = sprintf("Active : %s (%s)",
                      $self->{result_values}->{panSessionActive},
                      $self->{result_values}->{panSessionMax} != 0 ? $self->{result_values}->{active_prct} . " %" :
                      '-');
    } else {
        $msg = sprintf("Active : %s (%s)",
                      $self->{result_values}->{panVsysActiveSessions},
                      $self->{result_values}->{panVsysMaxSessions} != 0 ? $self->{result_values}->{active_prct} . " %" :
                      '-');
    }
    return $msg;
}

sub custom_active_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{panSessionActive} = $options{new_datas}->{$self->{instance} . '_panSessionActive'};
    $self->{result_values}->{panSessionMax} = $options{new_datas}->{$self->{instance} . '_panSessionMax'};
    $self->{result_values}->{panVsysActiveSessions} = $options{new_datas}->{$self->{instance} . '_panVsysActiveSessions'};
    $self->{result_values}->{panVsysMaxSessions} = $options{new_datas}->{$self->{instance} . '_panVsysMaxSessions'};
    $self->{result_values}->{active_prct} = 0;

    if ($self->{label} eq 'active') {
        if ($self->{result_values}->{panSessionMax} != 0) {
            $self->{result_values}->{active_prct} = $self->{result_values}->{panSessionActive} * 100 / $self->{result_values}->{panSessionMax};
        }
    } else {
        if ($self->{result_values}->{panVsysMaxSessions} != 0) {
            $self->{result_values}->{active_prct} = $self->{result_values}->{panVsysActiveSessions} * 100 / $self->{result_values}->{panVsysMaxSessions};
        }
    }
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, force_new_perfdata => 1, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'add-vsys'         => { name => 'add_vsys' },
    });

    return $self;
}


my $mapping_sessions = {
    panSessionMax                   => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.2' },
    panSessionActive                => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.3' },
    panSessionActiveTcp             => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.4' },
    panSessionActiveUdp             => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.5' },
    panSessionActiveICMP            => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.6' },
    #panSessionActiveSslProxy        => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.7' }, Cannot get the max if 0...
    panSessionSslProxyUtilization   => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.8' },
};

my $mapping_vsys = {
    panVsysName                 => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.9.1.2' },
    panVsysActiveSessions       => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.9.1.4' },
    panVsysMaxSessions          => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.9.1.5' },
    panVsysActiveTcpCps         => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.9.1.6' },
    panVsysActiveUdpCps         => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.9.1.7' },
    panVsysActiveOtherIpCps     => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.9.1.8' },
};

sub add_vsys {
    my ($self, %options) = @_;

    my $oid_panVsysEntry = '.1.3.6.1.4.1.25461.2.1.2.3.9.1';
    $self->{results} = $options{snmp}->get_table(oid => $oid_panVsysEntry,
                                                nothing_quit => 1);

    foreach my $oid (keys %{$self->{results}}) {
        next if $oid !~ /^$mapping_vsys->{panVsysName}->{oid}\.(.*)$/;
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping_vsys, results => $self->{results}, instance => $instance);

        $self->{vsys}->{$result->{panVsysName}} = {
            display                  => $result->{panVsysName},
            panVsysMaxSessions       => defined($result->{panVsysMaxSessions}) ? $result->{panVsysMaxSessions} : 0,
            panVsysActiveSessions    => $result->{panVsysActiveSessions},
            panVsysActiveTcpCps      => $result->{panVsysActiveTcpCps},
            panVsysActiveUdpCps      => $result->{panVsysActiveUdpCps},
        };

    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_panSession = '.1.3.6.1.4.1.25461.2.1.2.3';
    $self->{results} = $options{snmp}->get_table(oid => $oid_panSession,
                                                nothing_quit => 1);
    $self->{global} = $options{snmp}->map_instance(mapping => $mapping_sessions, results => $self->{results}, instance => '0');
    $self->{global}->{panSessionMax} = 0 if (!defined($self->{global}->{panSessionMax}));

    $self->add_vsys(snmp => $options{snmp})
        if (defined($self->{option_results}->{add_vsys}));
}

1;

__END__

=head1 MODE

Check sessions.

=over 8

=item B<--warning-*>

Threshold warning.
Global: 'active' (%), 'active-tcp', 'active-udp', 'active-icmp', 'active-ssl-proxy' (%).
Per vsys: 'active-vsys' (%), 'vsys-active-tcp' 'vsys-active-udp' 'vsys-active-other' 

=item B<--critical-*>

Threshold critical.
Global: 'active' (%), 'active-tcp', 'active-udp', 'active-icmp', 'active-ssl-proxy' (%).
Per vsys: 'active-vsys' (%), 'vsys-active-tcp' 'vsys-active-udp' 'vsys-active-other'

=back

=cut
