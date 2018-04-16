#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'connection status : ' . $self->{result_values}->{connectstatus} . ' [activation status: ' . $self->{result_values}->{activestatus} . ']';
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{activestatus} = $options{new_datas}->{$self->{instance} . '_activestatus'};
    $self->{result_values}->{connectstatus} = $options{new_datas}->{$self->{instance} . '_connectstatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vpn', type => 1, cb_prefix_output => 'prefix_vpn_output', message_multiple => 'All VPN tunnels are OK' },
    ];

    $self->{maps_counters}->{vpn} = [
        { label => 'traffic-in', set => {
                key_values => [ { name => 'traffic_in', diff => 1 }, { name => 'display' } ],
                per_second => 1, output_change_bytes => 2,
                output_template => 'Traffic In: %s %s/s',
                perfdatas => [
                    { label => 'traffic_in', value => 'traffic_in_per_second', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'traffic_out', diff => 1 }, { name => 'display' } ],
                per_second => 1, output_change_bytes => 2,
                output_template => 'Traffic Out: %s %s/s',
                perfdatas => [
                    { label => 'traffic_out', value => 'traffic_out_per_second', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display_absolute' },
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

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-name:s"     => { name => 'filter_name' },
                                "warning-status:s"  => { name => 'warning_status', default => '' },
                                "critical-status:s" => { name => 'critical_status', default => '%{connectstatus} eq "disconnected"' },
                                });
    return $self;
}

sub change_macros {
    my ($self, %options) = @_;

    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros();
    $instance_mode = $self;
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

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{activestatus}, %{connectstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{connectstatus} eq "disconnected"').
Can used special variables like: %{activestatus}, %{connectstatus}, %{display}

=back

=cut
