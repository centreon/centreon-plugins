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

package hardware::server::sun::mgmt_cards::mode::environmentv8xx;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use hardware::server::sun::mgmt_cards::lib::telnet;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"       => { name => 'hostname' },
                                  "port:s"           => { name => 'port', default => 23 },
                                  "username:s"       => { name => 'username' },
                                  "password:s"       => { name => 'password' },
                                  "timeout:s"        => { name => 'timeout', default => 30 },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a hostname.");
       $self->{output}->option_exit(); 
    }
    if (!defined($self->{option_results}->{username})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a username.");
       $self->{output}->option_exit(); 
    }
    if (!defined($self->{option_results}->{password})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a password.");
       $self->{output}->option_exit(); 
    }
}

sub run {
    my ($self, %options) = @_;

    my $telnet_handle = hardware::server::sun::mgmt_cards::lib::telnet::connect(
                            username => $self->{option_results}->{username},
                            password => $self->{option_results}->{password},
                            hostname => $self->{option_results}->{hostname},
                            port => $self->{option_results}->{port},
                            timeout => $self->{option_results}->{timeout},
                            output => $self->{output});
    my @lines = $telnet_handle->cmd("showenvironment");

    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "No problems detected.");
    
    my ($output) = join("", @lines);
    $output =~ s/\r//g;
    my $long_msg = $output;
    $long_msg =~ s/\|/~/mg;
    $self->{output}->output_add(long_msg => $long_msg); 
    
    if ($output =~ /^\s+POWER\s+GEN FAULT[^\[]+?\[([^\]]+?)][^\[]+?\[([^\]]+?)]/ims && defined($1)) {
        #   POWER                  GEN FAULT                      
        #   [ ON]                   [OFF]
        
        my $power_status = $1;
        my $genfault_status = $2;
        $genfault_status = centreon::plugins::misc::trim($genfault_status);
        
        if (defined($genfault_status) && $genfault_status !~ /^(OFF)$/i) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Gen Fault status is '" . $genfault_status . "'");
        }
    }
    
    if ($output =~ /^\s+REMOVE\s+DISK FAULT[^\[]+?\[([^\]]+?)][^\[]+?\[([^\]]+?)]/ims && defined($1)) {
        #   REMOVE                 DISK FAULT                      
        #   [OFF]                   [OFF]
        
        my $remove_status = $1;
        my $diskfault_status = $2;
        $diskfault_status = centreon::plugins::misc::trim($diskfault_status);
        
        if (defined($diskfault_status) && $diskfault_status !~ /^(OFF)$/i) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Disk Fault status is '" . $diskfault_status . "'");
        }
    }
    
    if ($output =~ /^\s+POWER FAULT\s+LEFT THERMAL FAULT[^\[]+?\[([^\]]+?)][^\[]+?\[([^\]]+?)]/ims && defined($1)) {
        #   POWER FAULT            LEFT THERMAL FAULT                      
        #   [OFF]                   [OFF]
        
        my $powerfault_status = $1;
        my $leftthermalfault_status = $2;
        $powerfault_status = centreon::plugins::misc::trim($powerfault_status);
        $leftthermalfault_status = centreon::plugins::misc::trim($leftthermalfault_status);
        
        if (defined($powerfault_status) && $powerfault_status !~ /^(OFF)$/i) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Power Fault status is '" . $powerfault_status . "'");
        }
        if (defined($leftthermalfault_status) && $leftthermalfault_status !~ /^(OFF)$/i) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Left Thermal Fault status is '" . $leftthermalfault_status . "'");
        }
    }
    
    if ($output =~ /^\s+RIGHT THERMAL FAULT\s+LEFT DOOR[^\[]+?\[([^\]]+?)][^\[]+?\[([^\]]+?)]/ims && defined($1)) {
        #   RIGHT THERMAL FAULT     LEFT DOOR                      
        #   [OFF]                   [OFF]
        
        my $rightthermalfault_status = $1;
        $rightthermalfault_status = centreon::plugins::misc::trim($rightthermalfault_status);
        
        if (defined($rightthermalfault_status) && $rightthermalfault_status !~ /^(OFF)$/i) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Right Thermal Fault status is '" . $rightthermalfault_status . "'");
        }
    }
    
    while (($output =~ /^DISK\s+([0-9]+):\s+\[PRESENT\]\s+\[([^\]]+)\]/imsg)) {
        #           Presence                Fault LED                
        #           --------                ---------
        #DISK    0:      [PRESENT]               [OFF]
        #DISK    1:      [EMPTY]
        
        my $disknum = $1;
        my $diskfault_status = $2;
        $diskfault_status = centreon::plugins::misc::trim($diskfault_status);
        
        if (defined($diskfault_status) && $diskfault_status !~ /^(OFF)$/i) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Disk $disknum status is '" . $diskfault_status . "'");
        }
    }
    
    if ($output =~ /^Fan Bank(.*?)=======/ims) {
        #Bank                    Presence        ON State        Status
        #----                    --------        --------        ------
        #CPU0_PRIM_FAN           [PRESENT]        [ON]           [OK]
        #CPU1_PRIM_FAN           [PRESENT]        [ON]           [OK]

        my $content = $1;
        while (($content =~ /^([^\s]+)\s+\[PRESENT\]\s+\[([^\]]+)\]\s+\[([^\]]+)\]/imsg)) {
            my $fanbank_name = $1;
            my $fanbank_status = $3;
            $fanbank_status = centreon::plugins::misc::trim($fanbank_status);
        
            if (defined($fanbank_status) && $fanbank_status !~ /^(OK)$/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Fan Bank '" . $fanbank_name . "' status is '" . $fanbank_status . "'");
            }
        }
    }
    
    if ($output =~ /^Power Supplies(.*?)=======/ims) {
        #Power Supplies:
        #---------------
        #
        #Supply     Status             Fan Fail    Temp Fail   CS Fail
        #------     ------------       --------    ---------   -------
        #1          NO AC POWER
        #2          OK
        my $content = $1;
        while (($content =~ /^\s*?([0-9]+)\s+(.*?)(\n|\s{2})/imsg)) {
            my $supplynum = $1;
            my $supply_status = $2;
            $supply_status = centreon::plugins::misc::trim($supply_status);
            
            if (defined($supply_status) && $supply_status !~ /^(OK)$/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Supply '" . $supplynum . "' status is '" . $supply_status . "'");
            }
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Sun v890 and v880 Hardware (through RSC card).

=over 8

=item B<--hostname>

Hostname to query.

=item B<--port>

telnet port (Default: 23).

=item B<--username>

telnet username.

=item B<--password>

telnet password.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=back

=cut
