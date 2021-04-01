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

package network::sonicwall::snmp::mode::vpn;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vpn', type => 1, cb_prefix_output => 'prefix_vpn_output', message_multiple => 'All VPN tunnels are OK' },
    ];

    $self->{maps_counters}->{vpn} = [
        { label => 'traffic-in', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub prefix_vpn_output {
    my ($self, %options) = @_;

    return "VPN '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $oid_sonicSAStatEntry = '.1.3.6.1.4.1.8741.1.3.2.1.1.1';
my $oid_sonicSAStatUserName = '.1.3.6.1.4.1.8741.1.3.2.1.1.1.14';
my $oid_sonicSAStatEncryptByteCount = '.1.3.6.1.4.1.8741.1.3.2.1.1.1.9';
my $oid_sonicSAStatDecryptByteCount = '.1.3.6.1.4.1.8741.1.3.2.1.1.1.11';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "sonicwall_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));

    $self->{vpn} = {};
    my $result = $options{snmp}->get_table(oid => $oid_sonicSAStatEntry, nothing_quit => 1);

    foreach my $oid (sort keys %{$result}) {
        next if ($oid !~ /^$oid_sonicSAStatUserName\.(.*)$/);
        my $instance = $1;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{$oid_sonicSAStatUserName . '.' . $instance} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{$oid_sonicSAStatUserName . '.' . $instance} . "': no matching filter.", debug => 1);
            next;
        }
	
        $self->{vpn}->{$result->{$oid_sonicSAStatUserName . '.' . $instance}} = { traffic_in => $result->{$oid_sonicSAStatEncryptByteCount . '.' . $instance} * 8,
                                                                                  traffic_out => $result->{$oid_sonicSAStatDecryptByteCount . '.' . $instance} * 8,
                                                                                  display => $result->{$oid_sonicSAStatUserName . '.' . $instance} };
    }
    
    if (scalar(keys %{$self->{vpn}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No vpn found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check VPN state and traffic.

=over 8

=item B<--filter-name>

Filter vpn name with regexp.

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in', 'traffic-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in', 'traffic-out'.

=back

=cut
