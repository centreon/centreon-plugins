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

package network::fritzbox::mode::traffic;

use base qw(centreon::plugins::mode);
use strict;
use warnings;
use centreon::plugins::statefile;
use network::fritzbox::mode::libgetdata;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"          => { name => 'hostname' },
                                  "port:s"              => { name => 'port', default => '49000' },
                                  "timeout:s"           => { name => 'timeout', default => 30 },
                                  "agent:s"             => { name => 'agent', default => 'igdupnp' },
                                  "warning-in:s"        => { name => 'warning_in', },
                                  "critical-in:s"       => { name => 'critical_in', },
                                  "warning-out:s"       => { name => 'warning_out', },
                                  "critical-out:s"      => { name => 'critical_out', },
                                  "units:s"             => { name => 'units', default => '%' },
                                });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify an Hostname.");
       $self->{output}->option_exit(); 
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-in', value => $self->{option_results}->{warning_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'in' threshold '" . $self->{option_results}->{warning_in} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-in', value => $self->{option_results}->{critical_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'in' threshold '" . $self->{option_results}->{critical_in} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-out', value => $self->{option_results}->{warning_out})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'out' threshold '" . $self->{option_results}->{warning_out} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-out', value => $self->{option_results}->{critical_out})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'out' threshold '" . $self->{option_results}->{critical_out} . "'.");
        $self->{output}->option_exit();
    }

    $self->{statefile_value}->check_options(%options);
    $self->{hostname} = $self->{option_results}->{hostname};
}

sub run {
    my ($self, %options) = @_;

    my $new_datas = {};
    $self->{statefile_value}->read(statefile => "cache_fritzbox_" . $self->{hostname}  . '_' . $self->{mode});
    $new_datas->{last_timestamp} = time();
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');

    ### GET DATA START
    network::fritzbox::mode::libgetdata::init($self, pfad => '/' . $self->{option_results}->{agent} . '/control/WANCommonIFC1',
                                                     uri => 'urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1');
    network::fritzbox::mode::libgetdata::call($self, soap_method => 'GetAddonInfos');
    my $NewTotalBytesSent = network::fritzbox::mode::libgetdata::value($self, path => '//GetAddonInfosResponse/NewTotalBytesSent');
    my $NewTotalBytesReceived = network::fritzbox::mode::libgetdata::value($self, path => '//GetAddonInfosResponse/NewTotalBytesReceived');

    network::fritzbox::mode::libgetdata::call($self, soap_method => 'GetCommonLinkProperties');
    my $NewLayer1UpstreamMaxBitRate = network::fritzbox::mode::libgetdata::value($self, path => '//GetCommonLinkPropertiesResponse/NewLayer1UpstreamMaxBitRate');
    my $NewLayer1DownstreamMaxBitRate = network::fritzbox::mode::libgetdata::value($self, path => '//GetCommonLinkPropertiesResponse/NewLayer1DownstreamMaxBitRate');
    ### GET DATA END

    # DID U KNOW? 
    # IN AND OUT IS BYTE
    # TOTAL IS BIT... 
    # so if you want all in BYTE... 
    # (8 BIT = 1 BYTE)
    # calc ($VAR / 8)
    $NewLayer1UpstreamMaxBitRate = ($NewLayer1UpstreamMaxBitRate);
    $NewLayer1DownstreamMaxBitRate = ($NewLayer1DownstreamMaxBitRate);
    $new_datas->{in} = ($NewTotalBytesReceived) * 8;
    $new_datas->{out} = ($NewTotalBytesSent) * 8;
    $self->{statefile_value}->write(data => $new_datas);
    
    my $old_in = $self->{statefile_value}->get(name => 'in');
    my $old_out = $self->{statefile_value}->get(name => 'out');
    if (!defined($old_timestamp) || !defined($old_in) || !defined($old_out)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }

    if ($new_datas->{in} < $old_in) {
        # We set 0. Has reboot.
        $old_in = 0;
    }
    if ($new_datas->{out} < $old_out) {
        # We set 0. Has reboot.
        $old_out = 0;
    }

    my $time_delta = $new_datas->{last_timestamp} - $old_timestamp;
    if ($time_delta <= 0) {
        # At least one second. two fast calls ;)
        $time_delta = 1;
    }
    my $in_per_sec = ($new_datas->{in} - $old_in) / $time_delta;
    my $out_per_sec = ($new_datas->{out} - $old_out) / $time_delta;

    my ($exit, $in_prct, $out_prct);

    $in_prct = $in_per_sec * 100 / $NewLayer1DownstreamMaxBitRate;
    $out_prct = $out_per_sec * 100 / $NewLayer1UpstreamMaxBitRate;
    if ($self->{option_results}->{units} eq '%') {
        my $exit1 = $self->{perfdata}->threshold_check(value => $in_prct, threshold => [ { label => 'critical-in', 'exit_litteral' => 'critical' }, { label => 'warning-in', exit_litteral => 'warning' } ]);
        my $exit2 = $self->{perfdata}->threshold_check(value => $out_prct, threshold => [ { label => 'critical-out', 'exit_litteral' => 'critical' }, { label => 'warning-out', exit_litteral => 'warning' } ]);
        $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
    } else {
        my $exit1 = $self->{perfdata}->threshold_check(value => $in_per_sec, threshold => [ { label => 'critical-in', 'exit_litteral' => 'critical' }, { label => 'warning-in', exit_litteral => 'warning' } ]);
        my $exit2 = $self->{perfdata}->threshold_check(value => $out_per_sec, threshold => [ { label => 'critical-out', 'exit_litteral' => 'critical' }, { label => 'warning-out', exit_litteral => 'warning' } ]);
        $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
    }
    $in_prct = sprintf("%.2f", $in_prct);
    $out_prct = sprintf("%.2f", $out_prct);

    ### Manage Output
    my ($in_value, $in_unit) = $self->{perfdata}->change_bytes(value => $in_per_sec, network => 1);
    my ($out_value, $out_unit) = $self->{perfdata}->change_bytes(value => $out_per_sec, network => 1);
    $self->{output}->output_add(short_msg => sprintf("Traffic In : %s/s (%s %%), Out : %s/s (%s %%)", 
                                    $in_value . $in_unit, $in_prct,
                                    $out_value . $out_unit, $out_prct));
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Traffic In : %s/s (%s %%), Out : %s/s (%s %%)", 
                                    $in_value . $in_unit, $in_prct,
                                    $out_value . $out_unit, $out_prct));
    }

    $self->{output}->perfdata_add(label => 'traffic_in', 
                                  unit => 'b/s',
                                  value => sprintf("%.2f", $in_per_sec),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-in', total => $NewLayer1DownstreamMaxBitRate),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-in', total => $NewLayer1DownstreamMaxBitRate),
                                  min => 0, max => $NewLayer1DownstreamMaxBitRate);
    $self->{output}->perfdata_add(label => 'traffic_out',
                                  unit => 'b/s',
                                  value => sprintf("%.2f", $out_per_sec),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-out', total => $NewLayer1UpstreamMaxBitRate),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-out', total => $NewLayer1UpstreamMaxBitRate),
                                  min => 0, max => $NewLayer1UpstreamMaxBitRate);
    
        

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

This Mode Checks your FritzBox Traffic on WAN Interface.
This Mode needs UPNP.

=over 8

=item B<--agent>

Fritzbox has two different UPNP Agents. upnp or igdupnp. (Default: igdupnp)

=item B<--warning-in>

Threshold warning for 'in' traffic.

=item B<--critical-in>

Threshold critical for 'in' traffic.

=item B<--warning-out>

Threshold warning for 'out' traffic.

=item B<--critical-out>

Threshold critical for 'out' traffic.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'b').

=item B<--hostname>

Hostname to query.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=back

=cut
