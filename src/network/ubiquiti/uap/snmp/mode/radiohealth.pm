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

package network::ubiquiti::uap::snmp::mode::radiohealth;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Radio ';
}

sub ap_long_output {
    my ($self, %options) = @_;

    return sprintf(
        'checking radio %s - %s ',
        $options{instance_value}->{display},
        $options{instance_value}->{radio}
    );
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "radio '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name                 => 'radio',
            type               => 3,
            cb_prefix_output   => 'prefix_ap_output',
            cb_long_output     => 'ap_long_output',
            indent_long_output => '    ',
            message_multiple   => 'All radios are ok',
            group              => [
                { name => 'health', type => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{health} = [
        { label => 'channel', nlabel => 'radio.channel.count', set => {
            key_values      => [ { name => 'channel' }, { name => 'display' } ],
            output_template => 'radio channels: %s',
            perfdatas       => [
                { template => '%s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'packets-in', nlabel => 'radio.packets.in.count', display_ok => 0, set => {
            key_values      => [ { name => 'packets_in' }, { name => 'display' } ],
            output_template => 'radio packets in: %s',
            perfdatas       => [
                { template => '%s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'packets-out', nlabel => 'radio.packets.out.count', display_ok => 0, set => {
            key_values      => [ { name => 'packets_out' }, { name => 'display' } ],
            output_template => 'radio packets in: %s',
            perfdatas       => [
                { template => '%s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'self-channel-in', nlabel => 'radio.self.channel.in.count', display_ok => 0, set => {
            key_values      => [ { name => 'self_channel_in' }, { name => 'display' } ],
            output_template => 'radio self channel in: %s',
            perfdatas       => [
                { template => '%s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'self-channel-out', nlabel => 'radio.self.channel.out.count', display_ok => 0, set => {
            key_values      => [ { name => 'self_channel_out' }, { name => 'display' } ],
            output_template => 'radio self channel out: %s',
            perfdatas       => [
                { template => '%s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
        { label => 'other-bss-channel', nlabel => 'radio.other.bss.channel.count', display_ok => 0, set => {
            key_values      => [ { name => 'other_bss_channel' }, { name => 'display' } ],
            output_template => 'radio other bss channel: %s',
            perfdatas       => [
                { template => '%s', label_extra_instance => 1, instance_use => 'display' }
            ]
        }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' }
    });

    return $self;
}

my $mapping = {
    name => { oid => '.1.3.6.1.4.1.41112.1.6.1.1.1.2' },#  unifiRadioName
};

my $mapping_stat = {
    radio             => { oid => '.1.3.6.1.4.1.41112.1.6.1.1.1.3' },# unifiRadioRadio
    rxPackets         => { oid => '.1.3.6.1.4.1.41112.1.6.1.1.1.4' },# unifiRadioRxPackets
    txPackets         => { oid => '.1.3.6.1.4.1.41112.1.6.1.1.1.5' },# unifiRadioTxPackets
    channel           => { oid => '.1.3.6.1.4.1.41112.1.6.1.1.1.6' },# unifiRadioCuTotal
    self_channel_in   => { oid => '.1.3.6.1.4.1.41112.1.6.1.1.1.7' },# unifiRadioCuSelfRx
    self_channel_out  => { oid => '.1.3.6.1.4.1.41112.1.6.1.1.1.8' },# unifiRadioCuSelfTx
    other_bss_channel => { oid => '.1.3.6.1.4.1.41112.1.6.1.1.1.9' },# unifiRadioOtherBss
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{radio} = {};

    my $request = [ { oid => $mapping->{name}->{oid} } ];

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => $request,
        return_type  => 1,
        nothing_quit => 1
    );

    foreach (sort keys %$snmp_result) {
        next if (!/^$mapping->{name}->{oid}\.(.*)/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (!defined($result->{name}) || $result->{name} eq '') {
            $self->{output}->output_add(long_msg =>
                "skipping Virtual Access Point '$instance': cannot get a name. please set it.",
                debug                            => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $result->{name} . "': no matching name filter.",
                debug                            => 1);
            next;
        }

        $self->{radio}->{ $result->{name} } = {
            instance => $instance,
            display  => $result->{name},
            health   => {
                display => $result->{name}
            }
        };
    }

    if (scalar(keys %{$self->{radio}}) <= 0) {
        $self->{output}->output_add(long_msg => 'no radio associated');
        return;
    }

    $options{snmp}->load(
        oids            => [ map($_->{oid}, values(%$mapping_stat)) ],
        instances       => [ map($_->{instance}, values %{$self->{radio}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (sort keys %{$self->{radio}}) {
        my $result = $options{snmp}->map_instance(
            mapping  => $mapping_stat,
            results  => $snmp_result,
            instance => $self->{radio}->{$_}->{instance}
        );

        $self->{radio}->{$_}->{radio} = $result->{radio};
        $self->{radio}->{$_}->{health}->{packets_in} = $result->{rxPackets};
        $self->{radio}->{$_}->{health}->{packets_out} = $result->{txPackets};

        $self->{radio}->{$_}->{health}->{channel} = $result->{channel};
        $self->{radio}->{$_}->{health}->{self_channel_in} = $result->{self_channel_in};
        $self->{radio}->{$_}->{health}->{self_channel_out} = $result->{self_channel_out};
        $self->{radio}->{$_}->{health}->{other_bss_channel} = $result->{other_bss_channel};
    }

    $self->{cache_name} = 'ubiquiti_uap_' . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ?
            md5_hex($self->{option_results}->{filter_counters}) :
            md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ?
            md5_hex($self->{option_results}->{filter_name}) :
            md5_hex('all'));
}

1;

__END__

=head1 MODE

Check AP health.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^traffic-in$'

=item B<--filter-name>

Filter access point name (can be a regexp)

=item B<--warning-channel>

Warning thresholds for number of channels.

=item B<--critical-channel>

Critical thresholds for number of channels.

=item B<--warning-packets-in>

Warning thresholds for number of packets in.

=item B<--critical-packets-in>

Critical thresholds for number of packets in.

=item B<--warning-packets-out>

Warning thresholds for number of packets out.

=item B<--critical-packets-out>

Critical thresholds for number of packets out.

=item B<--warning-self-channel-in>

Warning thresholds for self receive channel utilization.

=item B<--critical-self-channel-in>

Critical thresholds for self receive channel utilization.

=item B<--warning-self-channel-out>

Warning thresholds for self transmit channel utilization.

=item B<--critical-self-channel-out>

Critical thresholds for self transmit channel utilization.

=item B<--warning-other-bss-channel>

Warning thresholds for other BSS channel utilization.

=item B<--critical-other-bss-channel>

Critical thresholds for other BSS channel utilization.

=back

=cut
