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

package centreon::common::fortinet::fortigate::snmp::mode::sdwan;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub prefix_traffic_output {
    my ($self, %options) = @_;

    return 'traffic ';
}

sub sdwan_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking sd-wan '%s' [vdom: %s] [interface: %s]",
        $options{instance_value}->{name},
        $options{instance_value}->{vdom},
        $options{instance_value}->{ifName}
    );
}

sub prefix_sdwan_output {
    my ($self, %options) = @_;

    return sprintf(
        "sd-wan '%s' [vdom: %s] [interface: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{vdom},
        $options{instance_value}->{ifName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sdwan', type => 3, cb_prefix_output => 'prefix_sdwan_output', cb_long_output => 'sdwan_long_output',
          indent_long_output => '    ', message_multiple => 'All sd-wan links are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'traffic', type => 0, cb_prefix_output => 'prefix_traffic_output', skipped_code => { -10 => 1 } },
                { name => 'latency', type => 0, skipped_code => { -10 => 1 } },
                { name => 'jitter', type => 0, skipped_code => { -10 => 1 } },
                { name => 'packetloss', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{state} eq "down"',
            set => {
                key_values => [ { name => 'state' }, { name => 'vdom' }, { name => 'ifName' }, { name => 'name' }, { name => 'id' } ],
                output_template => 'state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{traffic} = [
        { label => 'traffic-in', nlabel => 'sdwan.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'in' }, { name => 'vdom' }, { name => 'name' }, { name => 'ifName' } ],
                output_template => 'in: %s %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'b/s',
                        instances => [$self->{result_values}->{vdom}, $self->{result_values}->{name}, $self->{result_values}->{ifName}],
                        value => sprintf('%.2f', $self->{result_values}->{in}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        },
        { label => 'traffic-out', nlabel => 'sdwan.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'out' }, { name => 'vdom' }, { name => 'name' }, { name => 'ifName' } ],
                output_template => 'out: %s %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'b/s',
                        instances => [$self->{result_values}->{vdom}, $self->{result_values}->{name}, $self->{result_values}->{ifName}],
                        value => sprintf('%.2f', $self->{result_values}->{out}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        },
        { label => 'traffic-bi', nlabel => 'sdwan.traffic.bi.bitspersecond', set => {
                key_values => [ { name => 'bi' }, { name => 'vdom' }, { name => 'name' }, { name => 'ifName' } ],
                output_template => 'bi: %s %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'b/s',
                        instances => [$self->{result_values}->{vdom}, $self->{result_values}->{name}, $self->{result_values}->{ifName}],
                        value => sprintf('%.2f', $self->{result_values}->{bi}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        }
    ];

    $self->{maps_counters}->{latency} = [
        { label => 'latency', nlabel => 'sdwan.latency.milliseconds', set => {
                key_values => [ { name => 'latency' }, { name => 'vdom' }, { name => 'name' }, { name => 'ifName' } ],
                output_template => 'latency: %sms',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'ms',
                        instances => [$self->{result_values}->{vdom}, $self->{result_values}->{name}, $self->{result_values}->{ifName}],
                        value => sprintf('%.2f', $self->{result_values}->{latency}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        }
    ];

    $self->{maps_counters}->{jitter} = [
        { label => 'jitter', nlabel => 'sdwan.jitter.milliseconds', set => {
                key_values => [ { name => 'jitter' }, { name => 'vdom' }, { name => 'name' }, { name => 'ifName' } ],
                output_template => 'jitter: %sms',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'ms',
                        instances => [$self->{result_values}->{vdom}, $self->{result_values}->{name}, $self->{result_values}->{ifName}],
                        value => sprintf('%.2f', $self->{result_values}->{jitter}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        }
    ];

    $self->{maps_counters}->{packetloss} = [
        { label => 'packetloss', nlabel => 'sdwan.packetloss.percentage', set => {
                key_values => [ { name => 'packet_loss' }, { name => 'vdom' }, { name => 'name' }, { name => 'ifName' } ],
                output_template => 'packet loss: %.3f%%',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => [$self->{result_values}->{vdom}, $self->{result_values}->{name}, $self->{result_values}->{ifName}],
                        value => sprintf('%.3f', $self->{result_values}->{packet_loss}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => 100
                    );
                }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-id:s'   => { name => 'filter_id' },
        'filter-name:s' => { name => 'filter_name' },
        'filter-vdom:s' => { name => 'filter_vdom' }
    });

    return $self;
}

my $mapping_status = { 0 => 'up', 1 => 'down' };

my $mapping = {
    state       => { oid => '.1.3.6.1.4.1.12356.101.4.9.2.1.4', map => $mapping_status }, # fgVWLHealthCheckLinkState
    latency     => { oid => '.1.3.6.1.4.1.12356.101.4.9.2.1.5' }, # fgVWLHealthCheckLinkLatency
    jitter      => { oid => '.1.3.6.1.4.1.12356.101.4.9.2.1.6' }, # fgVWLHealthCheckLinkJitter
    packet_loss => { oid => '.1.3.6.1.4.1.12356.101.4.9.2.1.9' }, # fgVWLHealthCheckLinkPacketLoss
    vdom        => { oid => '.1.3.6.1.4.1.12356.101.4.9.2.1.10' }, # fgVWLHealthCheckLinkVdom
    traffic_in  => { oid => '.1.3.6.1.4.1.12356.101.4.9.2.1.11' }, # fgVWLHealthCheckLinkBandwidthIn
    traffic_out => { oid => '.1.3.6.1.4.1.12356.101.4.9.2.1.12' }, # fgVWLHealthCheckLinkBandwidthOut
    traffic_bi  => { oid => '.1.3.6.1.4.1.12356.101.4.9.2.1.13' }, # fgVWLHealthCheckLinkBandwidthBi
    ifName      => { oid => '.1.3.6.1.4.1.12356.101.4.9.2.1.14' }  # fgVWLHealthCheckLinkIfName
};

sub manage_selection {
    my ($self, %options) = @_;

     $self->{cache_name} = 'fortinet_fortigate_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : 'all') . '_' .
            (defined($self->{option_results}->{filter_id}) ? md5_hex($self->{option_results}->{filter_id}) : 'all') . '_' .
            (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : 'all') . '_' .
            (defined($self->{option_results}->{filter_vdom}) ? md5_hex($self->{option_results}->{filter_vdom}) : 'all')
        );

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $oid_name = '.1.3.6.1.4.1.12356.101.4.9.2.1.2'; # fgVWLHealthCheckLinkName
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_name,
        nothing_quit => 1
    );

    $self->{sdwan} = {};
    foreach (keys %$snmp_result) {
        /^$oid_name\.(.*)$/;
        my $id = $1;

        if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $id !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(long_msg => "skipping sd-wan '" . $snmp_result->{$_} . "'.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$_} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping sd-wan '" . $snmp_result->{$_} . "'.", debug => 1);
            next;
        }

        $self->{sdwan}->{ $id } = {
            id => $id,
            name => $snmp_result->{$_}
        };
    }

    return if (scalar(keys %{$self->{sdwan}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_, keys(%{$self->{sdwan}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{sdwan}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        if (defined($self->{option_results}->{filter_vdom}) && $self->{option_results}->{filter_vdom} ne '' &&
            $result->{vdom} !~ /$self->{option_results}->{filter_vdom}/) {
            $self->{output}->output_add(long_msg => "skipping sd-wan '" . $self->{sdwan}->{$_}->{name} . "'.", debug => 1);
            next;
        }

        $self->{sdwan}->{$_}->{vdom} = $result->{vdom};
        $self->{sdwan}->{$_}->{ifName} = $result->{ifName};

        $self->{sdwan}->{$_}->{status} = {
            state => $result->{state},
            name => $self->{sdwan}->{$_}->{name},
            id => $self->{sdwan}->{$_}->{id},
            vdom => $result->{vdom},
            ifName => $result->{ifName}
        };

        $self->{sdwan}->{$_}->{traffic} = {
            name => $self->{sdwan}->{$_}->{name},
            vdom => $result->{vdom},
            ifName => $result->{ifName},
            in => $result->{traffic_in} * 1000,
            out => $result->{traffic_out} * 1000,
            bi => $result->{traffic_bi} * 1000,
        };

        $self->{sdwan}->{$_}->{jitter} = {
            name => $self->{sdwan}->{$_}->{name},
            vdom => $result->{vdom},
            ifName => $result->{ifName},
            jitter => $result->{jitter}
        };
        $self->{sdwan}->{$_}->{latency} = {
            name => $self->{sdwan}->{$_}->{name},
            vdom => $result->{vdom},
            ifName => $result->{ifName},
            latency => $result->{latency}
        };
        $self->{sdwan}->{$_}->{packetloss} = {
            name => $self->{sdwan}->{$_}->{name},
            vdom => $result->{vdom},
            ifName => $result->{ifName},
            packet_loss => $result->{packet_loss}
        };
    }
}

1;

__END__

=head1 MODE

Check sd-wan links.

=over 8

=item B<--filter-id>

Filter sd-wan links by ID (can be a regexp).

=item B<--filter-name>

Filter sd-wan links by name (can be a regexp).

=item B<--filter-vdom>

Filter sd-wan links by vdom name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{vdom}, %{id}, %{name}, %{ifName}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{vdom}, %{id}, %{name}, %{ifName}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} eq "down"').
You can use the following variables: %{state}, %{vdom}, %{id}, %{name}, %{ifName}

=item B<--warning-jitter>

Threshold.

=item B<--critical-jitter>

Threshold.

=item B<--warning-latency>

Threshold.

=item B<--critical-latency>

Threshold.

=item B<--warning-packetloss>

Threshold.

=item B<--critical-packetloss>

Threshold.

=item B<--warning-status>

Threshold.

=item B<--critical-status>

Threshold.

=item B<--warning-traffic-bi>

Threshold.

=item B<--critical-traffic-bi>

Threshold.

=item B<--warning-traffic-in>

Threshold.

=item B<--critical-traffic-in>

Threshold.

=item B<--warning-traffic-out>

Threshold.

=item B<--critical-traffic-out>

Threshold.

=back

=cut
