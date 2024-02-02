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

package centreon::common::fortinet::fortigate::snmp::mode::linkmonitor;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub prefix_output {
    my ($self, %options) = @_;

    return sprintf(
        "Link monitor '%s' [vdom: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{vdom}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'linkmonitor', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All link monitors are ok' }
    ];

    $self->{maps_counters}->{linkmonitor} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{state} eq "dead"',
            set => {
                key_values => [ { name => 'state' }, { name => 'vdom' }, { name => 'name' } ],
                output_template => 'state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'latency', nlabel => 'linkmonitor.latency.milliseconds', set => {
                key_values => [ { name => 'latency' }, { name => 'vdom' }, { name => 'name' } ],
                output_template => 'latency: %sms',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'ms',
                        instances => [$self->{result_values}->{vdom}, $self->{result_values}->{name}],
                        value => sprintf('%.3f', $self->{result_values}->{latency}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        },
        { label => 'jitter', nlabel => 'linkmonitor.jitter.milliseconds', set => {
                key_values => [ { name => 'jitter' }, { name => 'vdom' }, { name => 'name' } ],
                output_template => 'jitter: %sms',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'ms',
                        instances => [$self->{result_values}->{vdom}, $self->{result_values}->{name}],
                        value => sprintf('%.3f', $self->{result_values}->{jitter}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        },
        { label => 'packetloss', nlabel => 'linkmonitor.packetloss.percentage', set => {
                key_values => [ { name => 'packet_loss' }, { name => 'vdom' }, { name => 'name' } ],
                output_template => 'packet loss: %.3f%%',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => [$self->{result_values}->{vdom}, $self->{result_values}->{name}],
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-id:s'   => { name => 'filter_id' },
        'filter-name:s' => { name => 'filter_name' },
        'filter-vdom:s' => { name => 'filter_vdom' }
    });

    return $self;
}

my $mapping_status = { 0 => 'alive', 1 => 'dead' };

my $mapping = {
    name        => { oid => '.1.3.6.1.4.1.12356.101.4.8.2.1.2' }, # fgLinkMonitorName
    state       => { oid => '.1.3.6.1.4.1.12356.101.4.8.2.1.3', map => $mapping_status }, # fgLinkMonitorState
    latency     => { oid => '.1.3.6.1.4.1.12356.101.4.8.2.1.4' }, # fgLinkMonitorLatency
    jitter      => { oid => '.1.3.6.1.4.1.12356.101.4.8.2.1.5' }, # fgLinkMonitorJitter
    packet_loss => { oid => '.1.3.6.1.4.1.12356.101.4.8.2.1.8' }, # fgLinkMonitorPacketLoss
    vdom        => { oid => '.1.3.6.1.4.1.12356.101.4.8.2.1.9' }, # fgLinkMonitorVdom
};

my $oid_MappingEntry = '.1.3.6.1.4.1.12356.101.4.8.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_MappingEntry,
        nothing_quit => 1
    );

    $self->{linkmonitor} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $instance !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(long_msg => "With filter-id: $self->{option_results}->{filter_id} - Skipping link monitor '" . $snmp_result->{$oid} . " with id '" . $instance . "'.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "With filter-name: $self->{option_results}->{filter_name} - Skipping link monitor '" . $snmp_result->{$oid} . " with id '" . $instance . "'.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_vdom}) && $self->{option_results}->{filter_vdom} ne '' &&
            $result->{vdom} !~ /$self->{option_results}->{filter_vdom}/) {
            $self->{output}->output_add(long_msg => "With filter-vdom: $self->{option_results}->{filter_vdom} - Skipping vdom '" . $result->{vdom} . "'.", debug => 1);
            next;
        }

        # Remoove the "%" at the end of the result.
        chop($result->{packet_loss});

        $self->{linkmonitor}->{ $instance } = {
            id    => $instance,
            name  => $result->{name},
            state => $result->{state},
            latency => $result->{latency},
            jitter => $result->{jitter},
            packet_loss => $result->{packet_loss},
            vdom => $result->{vdom}
        };

    }

    return if (scalar(keys %{$self->{linkmonitor}}) <= 0);
    # Return : OK: if empty => User needs to set up filters to avoid this mysterious OK result.

}

1;

__END__

=head1 MODE

Check link monitor.

=over 8

=item B<--filter-id>

Filter link monitor by ID (can be a regexp).

=item B<--filter-name>

Filter link monitor by name (can be a regexp).

=item B<--filter-vdom>

Filter link monitor by vdom name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{vdom}, %{id}, %{name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{vdom}, %{id}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (Default: '%{state} eq "dead"').
You can use the following variables: %{state}, %{vdom}, %{id}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'latency', 'jitter', 'packetloss'.

=back

=cut