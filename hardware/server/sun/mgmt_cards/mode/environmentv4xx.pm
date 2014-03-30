################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package hardware::server::sun::mgmt_cards::mode::environmentv4xx;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use hardware::server::sun::mgmtcards::lib::telnet;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
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

    my $telnet_handle = hardware::server::sun::mgmtcards::lib::telnet::connect(
                            username => $self->{option_results}->{username},
                            password => $self->{option_results}->{password},
                            hostname => $self->{option_results}->{hostname},
                            port => $self->{option_results}->{port},
                            output => $self->{output});
    my @lines = $telnet_handle->cmd("showenvironment");

    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "No problems detected.");
    
    my ($output) = join("", @lines);
    $output =~ s/\r//g;
    my $long_msg = $output;
    $long_msg =~ s/\|/~/mg;
    $self->{output}->output_add(long_msg => $long_msg); 
    
    if ($output =~ /^System LED Status:[^\[]+?\[([^\]]+?)][^\[]+?\[([^\]]+?)]/ims && defined($1)) {
        #System LED Status: LOCATOR     FAULT    POWER
        #        [OFF]      [OFF]    [ ON]
        
        my $genfault_status = $2;
        $genfault_status = centreon::plugins::misc::trim($genfault_status);
        
        if (defined($genfault_status) && $genfault_status !~ /^(OFF)$/i) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Gen Fault status is '" . $genfault_status . "'");
        }
    }

    if ($output =~ /^Disk LED Status:(.*?)=======/ims) {
        #Disk LED Status:    OK = GREEN  ERROR = YELLOW
        #    DISK  1: [EMPTY]
        #    DISK  0:    [OK]
        my $content = $1;
        while (($content =~ /DISK\s+([0-9]+)\s*:\s+\[([^\]]+?)\]/imsg)) {
            my $disknum = $1;
            my $disk_status = $2;
            $disk_status = centreon::plugins::misc::trim($disk_status);
            
            if (defined($disk_status) && $disk_status !~ /^(OK|EMPTY)$/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Disk $disknum status is '" . $disk_status . "'");
            }
        }
    }
    
    if ($output =~ /^Fan Tray :(.*?)=======/ims) {
        #Fan Tray :
        #----------
        #
        #Tray                    Speed   Status
        #----                    -----   ------
        #FAN TRAY0 CPU FAN0       5555   [OK]
        #FAN TRAY0 CPU FAN1       4000   [OK]
        #FAN TRAY0 CPU FAN2       3846   [OK]
        #FAN TRAY1  IO FAN0       4000   [OK]
        #FAN TRAY1  IO FAN1       4166   [OK]
        #FAN TRAY1  IO FAN2          0   [UNKNOWN]
        #
        # Can be [FAILED], [OK], [UNKNOWN]
        # If system is poweroff, nothing displayed.
        my $content = $1;
        while (($content =~ /\n([^\n]*?)(\s+[0-9]+\s+|\s+)\[(.*?)\]$/imsg)) {
            my $fan_name = $1;
            my $fan_status = $3;
            $fan_name = centreon::plugins::misc::trim($fan_name);
            $fan_status = centreon::plugins::misc::trim($fan_status);
            
            if (defined($fan_status) && $fan_status !~ /^(OK)$/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Fan '" . $fan_name . "' status is '" . $fan_status . "'");
            }
        }
    }
    
    if ($output =~ /^Power Supplies(.*?)=======/ims) {
        # Power Supplies:
        #---------------
        #
        #Supply     Status             PS Fault   Fan Fault  Temp Fault
        #------     ------------       --------   ---------  ----------
        #  0        OK                 OFF        OFF        OFF
        #  1        OK                 OFF        OFF        OFF
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

Check Sun 'v480' and 'v490' Hardware (through RSC card).

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
