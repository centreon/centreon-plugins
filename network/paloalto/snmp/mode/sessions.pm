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

package network::paloalto::snmp::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_vsys_active_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => $self->{label},
        nlabel => $self->{nlabel},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{sessions_active},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{sessions_max} != 0 ? $self->{result_values}->{sessions_max} : undef
    );
}

sub custom_active_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => $self->{label},
        nlabel => $self->{nlabel},
        value => $self->{result_values}->{sessions_active},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{sessions_max} != 0 ? $self->{result_values}->{sessions_max} : undef
    );
}

sub custom_active_output {
    my ($self, %options) = @_;

    return sprintf('active: %s (%s)',
        $self->{result_values}->{sessions_active},
        $self->{result_values}->{sessions_max} != 0 ? $self->{result_values}->{sessions_max} : '-'
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'vsys', type => 1, cb_prefix_output => 'prefix_vsys_output', message_multiple => 'Vsys sessions metrics are OK', skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'active', nlabel => 'sessions.active.count', set => {
                key_values => [ { name => 'sessions_active' }, { name => 'sessions_max' } ],
                closure_custom_output => $self->can('custom_active_output'),
                closure_custom_perfdata => $self->can('custom_active_perfdata')
            }
        },
        { label => 'active-prct', nlabel => 'sessions.active.percentage', display_ok => 0, set => {
                key_values => [ { name => 'sessions_active_prct' } ],
                output_template => 'active: %.2f %%',
                perfdatas => [
                    { label => 'active_prct', value => 'sessions_active_prct', template => '%.2f', unit => '%',
                      min => 0, max => 100 }
                ]
            }
        },
        { label => 'active-tcp', nlabel => 'sessions.active.tcp.count', set => {
                key_values => [ { name => 'panSessionActiveTcp' } ],
                output_template => 'active TCP: %s',
                perfdatas => [
                    { label => 'active_tcp', value => 'panSessionActiveTcp', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'active-udp', nlabel => 'sessions.active.udp.count', set => {
                key_values => [ { name => 'panSessionActiveUdp' } ],
                output_template => 'active UDP: %s',
                perfdatas => [
                    { label => 'active_udp', value => 'panSessionActiveUdp', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'active-icmp', nlabel => 'sessions.active.icmp.count', set => {
                key_values => [ { name => 'panSessionActiveICMP' } ],
                output_template => 'active ICMP: %s',
                perfdatas => [
                    { label => 'active_icmp', value => 'panSessionActiveICMP', template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vsys} = [
        { label => 'vsys-active', nlabel => 'vsys.sessions.active.count', set => {
                key_values => [ { name => 'sessions_active' }, { name => 'sessions_max' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_active_output'),
                closure_custom_perfdata => $self->can('custom_vsys_active_perfdata')
            }
        },
        { label => 'vsys-active-prct', nlabel => 'vsys.sessions.active.percentage', display_ok => 0, set => {
                key_values => [ { name => 'sessions_active_prct' } ],
                output_template => 'active: %.2f %%',
                perfdatas => [
                    { label => 'active_prct', value => 'sessions_active_prct', template => '%.2f', unit => '%',
                      min => 0, max => 100 }
                ]
            }
        },
        { label => 'vsys-active-tcp', nlabel => 'vsys.sessions.active.tcp.count', set => {
                key_values => [ { name => 'panVsysActiveTcpCps' }, { name => 'display' } ],
                output_template => 'active TCP: %s',
                perfdatas => [
                    { label => 'active_tcp', value => 'panVsysActiveTcpCps', template => '%s',
                      label_extra_instance => 1, min => 0 }
                ]
            }
        },
        { label => 'vsys-active-udp', nlabel => 'vsys.sessions.active.udp.count', set => {
                key_values => [ { name => 'panVsysActiveUdpCps' }, { name => 'display' } ],
                output_template => 'active UDP: %s',
                perfdatas => [
                    { label => 'active_udp', value => 'panVsysActiveUdpCps', template => '%s',
                      label_extra_instance => 1, min => 0 }
                ]
            }
        },
        { label => 'vsys-active-other', nlabel => 'vsys.sessions.active.other.count', set => {
                key_values => [ { name => 'panVsysActiveOtherIpCps' }, { name => 'display' } ],
                output_template => 'other: %s',
                perfdatas => [
                    { label => 'active_other', value => 'panVsysActiveOtherIpCps', template => '%s',
                      label_extra_instance => 1, min => 0 }
                ]
            }
        }
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Sessions ";
}

sub prefix_vsys_output {
    my ($self, %options) = @_;

    return "Vsys '" . $options{instance_value}->{display} . "' sessions ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, force_new_perfdata => 1, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'add-vsys' => { name => 'add_vsys' },
    });

    return $self;
}


my $mapping_sessions = {
    sessions_max                  => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.2' }, # panSessionMax
    sessions_active               => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.3' }, # panSessionActive
    panSessionActiveTcp           => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.4' },
    panSessionActiveUdp           => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.5' },
    panSessionActiveICMP          => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.6' },
    panSessionSslProxyUtilization => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.8' }
};
my $mapping_vsys = {
    display                 => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.9.1.2' }, # panVsysName
    sessions_active         => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.9.1.4' }, # panVsysActiveSessions
    sessions_max            => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.9.1.5' }, # panVsysMaxSessions
    panVsysActiveTcpCps     => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.9.1.6' },
    panVsysActiveUdpCps     => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.9.1.7' },
    panVsysActiveOtherIpCps => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.9.1.8' }
};

sub add_vsys {
    my ($self, %options) = @_;

    my $oid_panVsysEntry = '.1.3.6.1.4.1.25461.2.1.2.3.9.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_panVsysEntry,
        nothing_quit => 1
    );

    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping_vsys->{display}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping_vsys, results => $snmp_result, instance => $instance);
        $self->{vsys}->{$result->{display}} = $result;
        $self->{vsys}->{$result->{display}}->{sessions_max} = 0 if (!defined($result->{sessions_max}));
        $self->{vsys}->{$result->{display}}->{sessions_active_prct} = $result->{sessions_active} * 100 / $self->{vsys}->{$result->{display}}->{sessions_max}
            if ($self->{vsys}->{$result->{display}}->{sessions_max} != 0);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping_sessions)) ],
        nothing_quit => 1
    );
    $self->{global} = $options{snmp}->map_instance(mapping => $mapping_sessions, results => $snmp_result, instance => '0');
    $self->{global}->{sessions_max} = 0 if (!defined($self->{global}->{sessions_max}));
    $self->{global}->{sessions_active_prct} = $self->{global}->{sessions_active} * 100 / $self->{global}->{sessions_max}
        if ($self->{global}->{sessions_max} != 0);

    $self->add_vsys(snmp => $options{snmp})
        if (defined($self->{option_results}->{add_vsys}));
}

1;

__END__

=head1 MODE

Check sessions.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Global: 'active', 'active-prct', (%), 'active-tcp', 'active-udp', 'active-icmp',
Per vsys: 'vsys-active', 'vsys-active-prct' (%), 'vsys-active-tcp' 'vsys-active-udp' 'vsys-active-other'.

=back

=cut
