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

package network::ubiquiti::airfiber::snmp::mode::radios;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [enabled: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{enabled}
    );
}

sub radio_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking radio interface '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_radio_output {
    my ($self, %options) = @_;

    return sprintf(
        "radio interface '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_signal_output {
    my ($self, %options) = @_;

    return 'signal ';
}

sub prefix_traffic_output {
    my ($self, %options) = @_;

    return 'traffic ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'radios', type => 3, cb_prefix_output => 'prefix_radio_output', cb_long_output => 'radio_long_output',
          indent_long_output => '    ', message_multiple => 'All radio interfaces are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'signal', type => 0, cb_prefix_output => 'prefix_signal_output', skipped_code => { -10 => 1 } },
                { name => 'traffic', type => 0, cb_prefix_output => 'prefix_traffic_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status', type => 2, critical_default => '%{enabled} eq "yes" and %{state} eq "down"',
            set => {
                key_values => [ { name => 'enabled' }, { name => 'state' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{signal} = [
        { label => 'chain0-signal-receive-power', nlabel => 'radio.interface.chain0.signal.receive.power.dbm', set => {
                key_values => [ { name => 'chain0_in_power' } ],
                output_template => 'chain0 receive power: %s dBm',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'dBm', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'chain1-signal-receive-power', nlabel => 'radio.interface.chain1.signal.receive.power.dbm', set => {
                key_values => [ { name => 'chain1_in_power' } ],
                output_template => 'chain1 receive power: %s dBm',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'dBm', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{traffic} = [
        { label => 'traffic-in', nlabel => 'radio.interface.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 } ],
                output_template => 'in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'radio.interface.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 } ],
                output_template => 'out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1 }
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
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my $map_state = { 0 => 'down', 1 => 'up' };
my $map_enabled = { 1 => 'yes', 2 => 'no' };

my $mapping = {
    enabled         => { oid => '.1.3.6.1.4.1.41112.1.3.1.1.2', map => $map_enabled }, # radioEnable
    state           => { oid => '.1.3.6.1.4.1.41112.1.3.2.1.26', map => $map_state },  # radioLinkState
    chain0_in_power => { oid => '.1.3.6.1.4.1.41112.1.3.2.1.11' }, # rxPower0
    chain1_in_power => { oid => '.1.3.6.1.4.1.41112.1.3.2.1.14' }, # rxPower1
    total_out       => { oid => '.1.3.6.1.4.1.41112.1.3.3.1.6' },  # txOctetsOK
    total_in        => { oid => '.1.3.6.1.4.1.41112.1.3.3.1.19' }  # rxTotalOctets
};

sub manage_selection {
    my ($self, %options) = @_;

     $self->{cache_name} = 'ubiquiti_airfiber_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));

    my $oid_name = '.1.3.6.1.4.1.41112.1.3.1.1.14'; # linkName
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_name,
        nothing_quit => 1
    );

    $self->{radios} = {};
    foreach (keys %$snmp_result) {
        /\.(\d+)$/;
        my $instance = $1;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$_} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping radio interface '" . $snmp_result->{$_} . "'.", debug => 1);
            next;
        }

        $self->{radios}->{ $snmp_result->{$_} } = {
            name => $snmp_result->{$_},
            instance => $instance
        };
    }

    return if (scalar(keys %{$self->{radios}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_->{instance}, values(%{$self->{radios}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{radios}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $self->{radios}->{$_}->{instance});

        $self->{radios}->{$_}->{status} = { state => $result->{state}, enabled => $result->{enabled}, name => $_ };
        $self->{radios}->{$_}->{traffic} = { traffic_in => $result->{total_in} * 8, traffic_out => $result->{total_out} * 8 };
        $self->{radios}->{$_}->{signal} = { chain0_in_power => $result->{chain0_in_power}, chain1_in_power => $result->{chain1_in_power} };
    }
}

1;

__END__

=head1 MODE

Check radio interfaces.

=over 8

=item B<--filter-name>

Filter interface by name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{enabled}, %{state}, %{name}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{enabled}, %{state}, %{name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{enabled} eq "yes" and %{state} eq "down"').
Can used special variables like: %{enabled}, %{state}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'traffic-in', 'traffic-out', 'chain0-signal-receive-power', 'chain1-signal-receive-power'.

=back

=cut
