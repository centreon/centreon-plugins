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

package network::sonus::sbc::snmp::mode::callstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_port_output {
    my ($self, %options) = @_;

    return "Port '" . $options{instance_value}->{display} . "' number of calls ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'port', type => 1, cb_prefix_output => 'prefix_port_output', message_multiple => 'All ports call statistics are ok' }
    ];

    $self->{maps_counters}->{port} = [
        { label => 'current', nlabel => 'port.calls.current.count', set => {
                key_values => [ { name => 'current' }, { name => 'display' } ],
                output_template => 'current: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'total', nlabel => 'port.calls.total.count', set => {
                key_values => [ { name => 'total', diff => 1 }, { name => 'display' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'connected', nlabel => 'port.calls.connected.count', set => {
                key_values => [ { name => 'connected', diff => 1 }, { name => 'display' } ],
                output_template => 'connected: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'refused', nlabel => 'port.calls.refused.count', set => {
                key_values => [ { name => 'refused', diff => 1 }, { name => 'display' } ],
                output_template => 'refused: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'errored', nlabel => 'port.calls.errored.count', set => {
                key_values => [ { name => 'errored', diff => 1 }, { name => 'display' } ],
                output_template => 'errored: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'blocked', nlabel => 'port.calls.blocked.count',  set => {
                key_values => [ { name => 'blocked', diff => 1 }, { name => 'display' } ],
                output_template => 'blocked: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

my $mapping = {
    uxPTCurrentCalls    => { oid => '.1.3.6.1.4.1.177.15.1.5.1.2.1.5' },
    uxPTTotalCalls      => { oid => '.1.3.6.1.4.1.177.15.1.5.1.2.1.6' },
    uxPTConnectedCalls  => { oid => '.1.3.6.1.4.1.177.15.1.5.1.2.1.7' },
    uxPTRefusedCalls    => { oid => '.1.3.6.1.4.1.177.15.1.5.1.2.1.8' },
    uxPTErroredCalls    => { oid => '.1.3.6.1.4.1.177.15.1.5.1.2.1.9' },
    uxPTBlockedCalls    => { oid => '.1.3.6.1.4.1.177.15.1.5.1.2.1.18' }
};
my $oid_uxPortTable = '.1.3.6.1.4.1.177.15.1.5.1.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_uxPortTable,
        nothing_quit => 1
    );

    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{uxPTCurrentCalls}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{port}->{$instance} = {
            current		=> $result->{uxPTCurrentCalls},
            total		=> $result->{uxPTTotalCalls},
            connected	        => $result->{uxPTConnectedCalls},
            refused		=> $result->{uxPTRefusedCalls},
            errored		=> $result->{uxPTErroredCalls},
            blocked		=> $result->{uxPTBlockedCalls},
            display		=> $instance
        };
    }

    $self->{cache_name} = "sonus_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check port call statistics.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds. Can be: 'current', 'total', 'connected', 'refused', 'errored', 'blocked'.

=back

=cut
