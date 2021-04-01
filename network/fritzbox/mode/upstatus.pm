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

package network::fritzbox::mode::upstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use network::fritzbox::mode::libgetdata;
use POSIX;

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
                                  "warning:s"           => { name => 'warning', },
                                  "critical:s"          => { name => 'critical',  },
                                  "seconds"             => { name => 'seconds', },
                                });
    return $self;
}

sub check_options {

    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify an Hostname.");
       $self->{output}->option_exit(); 
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    my $exit_code;
    
    network::fritzbox::mode::libgetdata::init($self, pfad => '/' . $self->{option_results}->{agent} . '/control/WANCommonIFC1',
                                                     uri => 'urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1');
    network::fritzbox::mode::libgetdata::call($self, soap_method => 'GetCommonLinkProperties');
    my $WANAccessType = network::fritzbox::mode::libgetdata::value($self, path => '//GetCommonLinkPropertiesResponse/NewWANAccessType');
    my $LinkStatus = network::fritzbox::mode::libgetdata::value($self, path => '//GetCommonLinkPropertiesResponse/NewPhysicalLinkStatus');

    network::fritzbox::mode::libgetdata::init($self, pfad => '/' . $self->{option_results}->{agent} . '/control/WANIPConn1',
                                                     uri => 'urn:schemas-upnp-org:service:WANIPConnection:1');
    network::fritzbox::mode::libgetdata::call($self, soap_method => 'GetStatusInfo');
    my $uptime = network::fritzbox::mode::libgetdata::value($self, path => '//GetStatusInfoResponse/NewUptime');
    my $ConnectionStatus = network::fritzbox::mode::libgetdata::value($self, path => '//GetStatusInfoResponse/NewConnectionStatus');

    $exit_code = $self->{perfdata}->threshold_check(value => floor($uptime),
                              threshold => [ { label => 'critical', exit_litteral => 'critical' }, 
                                             { label => 'warning', exit_litteral => 'warning' } ]);

    if ($LinkStatus !~ /^up$/i || $ConnectionStatus !~ /^connected$/i) {
        $exit_code = 'critical';
    }
    
    $self->{output}->perfdata_add(label => 'uptime',
                                  value => floor($uptime),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Physical Link is " . $LinkStatus . " and " . $WANAccessType . " is " . $ConnectionStatus .  
                                " since: %s", defined($self->{option_results}->{seconds}) ? floor($uptime) . " seconds" : floor($uptime / 86400) . " days" ));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

This Mode Checks Physical Link Status, Connection Status and Uptime of your Fritz!Box Internet Connection.
This Mode needs UPNP.

=over 8

=item B<--agent>

Fritzbox has two different UPNP Agents. upnp or igdupnp. (Default: igdupnp)

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=item B<--seconds>

Display uptime in seconds.

=item B<--hostname>

Hostname to query.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=back

=cut
