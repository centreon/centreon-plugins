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

package network::sophos::es::snmp::mode::message;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'sea_msg', type => 1, cb_prefix_output => 'prefix_seamsg_output', message_multiple => 'All messages are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'queue', set => {
                key_values => [ { name => 'queue' } ],
                output_template => 'Current Queue : %s',
                perfdatas => [
                    { label => 'queue', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total-msg-in', set => {
                key_values => [ { name => 'total_in', per_second => 1 } ],
                output_template => 'Total Message In : %.2f/s',
                perfdatas => [
                    { label => 'total_msg_in', template => '%.2f', unit => '/s', min => 0 }
                ]
            }
        },
        { label => 'total-msg-out', set => {
                key_values => [ { name => 'total_out', per_second => 1 } ],
                output_template => 'Total Message Out : %.2f/s',
                perfdatas => [
                    { label => 'total_msg_out', template => '%.2f', unit => '/s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{sea_msg} = [
        { label => 'msg-in', set => {
                key_values => [ { name => 'in', per_second => 1 }, { name => 'display' } ],
                output_template => 'In : %.2f/s',
                perfdatas => [
                    { label => 'msg_in', template => '%.2f', unit => '/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'msg-out', set => {
                key_values => [ { name => 'out', per_second => 1 }, { name => 'display' } ],
                output_template => 'Out : %.2f/s',
                perfdatas => [
                    { label => 'msg_out', template => '%.2f', unit => '/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_seamsg_output {
    my ($self, %options) = @_;
    
    return "Message '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-type:s' => { name => 'filter_type' },
    });

    return $self;
}

my $mapping = {
    counterType     => { oid => '.1.3.6.1.4.1.2604.1.1.1.4.1.2' },
    counterInbound  => { oid => '.1.3.6.1.4.1.2604.1.1.1.4.1.3' },
    counterOutbound => { oid => '.1.3.6.1.4.1.2604.1.1.1.4.1.4' },
};

my $oid_sophosStatisticsEmail = '.1.3.6.1.4.1.2604.1.1.1';
my $oid_seaStatisticsQueuedMessages = '.1.3.6.1.4.1.2604.1.1.1.5';

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_table(oid => $oid_sophosStatisticsEmail, nothing_quit => 1);

    $self->{cache_name} = "sophos_es_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_type}) ? md5_hex($self->{option_results}->{filter_type}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    $self->{global} = { total_in => 0, total_out => 0 };
    $self->{global}->{queue} = defined($results->{$oid_seaStatisticsQueuedMessages}) ? $results->{$oid_seaStatisticsQueuedMessages} : undef;

    $self->{sea_msg} = {};
    foreach my $oid (keys %$results) {
        next if ($oid !~ /^$mapping->{counterType}->{oid}\.(.*)$/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $result->{counterType} !~ /$self->{option_results}->{filter_type}/i) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{counterType} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{sea_msg}->{lc($result->{counterType})} = {
            display => lc($result->{counterType}), 
            in => $result->{counterInbound},
            out => $result->{counterOutbound}
        };

        $self->{global}->{total_in} += $result->{counterInbound};
        $self->{global}->{total_out} += $result->{counterOutbound};
    }
}

1;

__END__

=head1 MODE

Check message statistics.

=over 8

=item B<--filter-type>

Filter message type (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='queue'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: queue, total-msg-in, total-msg-out, msg-in, msg-out.

=back

=cut
