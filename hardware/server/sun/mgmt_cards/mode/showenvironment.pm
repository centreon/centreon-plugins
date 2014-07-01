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

package hardware::server::sun::mgmt_cards::mode::showenvironment;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

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
                                  "command-plink:s"  => { name => 'command_plink', default => 'plink' },
                                  "ssh"              => { name => 'ssh' },
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

    if (!defined($self->{option_results}->{ssh})) {
        require hardware::server::sun::mgmt_cards::lib::telnet;
    }
}

sub ssh_command {
    my ($self, %options) = @_;
    
    my $cmd_in = $self->{option_results}->{username} . '\n' . $self->{option_results}->{password} . '\nshowenvironment\nlogout\n';
    my $cmd = "echo -e '$cmd_in' | " . $self->{option_results}->{command_plink} . " -batch " . $self->{option_results}->{hostname} . " 2>&1";
    my ($lerror, $stdout, $exit_code) = centreon::plugins::misc::backtick(
                                                 command => $cmd,
                                                 timeout => $self->{option_results}->{timeout},
                                                 wait_exit => 1
                                                 );
    $stdout =~ s/\r//g;
    if ($lerror <= -1000) {
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => $stdout);
        $self->{output}->display();
        $self->{output}->exit();
    }
    if ($exit_code != 0) {
        $stdout =~ s/\n/ - /g;
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Command error: $stdout");
        $self->{output}->display();
        $self->{output}->exit();
    }

    if ($stdout !~ /Environmental Status/mi) {
        $self->{output}->output_add(long_msg => $stdout);
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Command 'showenvironment' problems (see additional info).");
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    return $stdout;
}

sub run {
    my ($self, %options) = @_;
    my $output;
    
    if (defined($self->{option_results}->{ssh})) {
        $output = $self->ssh_command();
    } else {
        my $telnet_handle = hardware::server::sun::mgmt_cards::lib::telnet::connect(
                                username => $self->{option_results}->{username},
                                password => $self->{option_results}->{password},
                                hostname => $self->{option_results}->{hostname},
                                port => $self->{option_results}->{port},
                                timeout => $self->{option_results}->{timeout},
                                output => $self->{output});
        my @lines = $telnet_handle->cmd("showenvironment");
        $output = join("", @lines);
    }
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "No problems detected.");
    
    $output =~ s/\r//g;
    my $long_msg = $output;
    $long_msg =~ s/\|/~/mg;
    $self->{output}->output_add(long_msg => $long_msg); 
    
    if ($output =~ /^System Temperatures.*?\n.*?\n.*?\n.*?\n(.*?)\n\n/ims && defined($1)) {
        #Sensor         Status    Temp LowHard LowSoft LowWarn HighWarn HighSoft HighHard
        #--------------------------------------------------------------------------------
        #MB.P0.T_CORE    OK         62     --      --      --      88       93      100
        
        foreach (split(/\n/, $1)) {
            next if (! /^([^\s]+)\s+([^\s].*?)\s{2}/);
            my $sensor_status = defined($2) ? $2 : undef;
            my $sensor_name = defined($1) ? $1 : undef;
            if (defined($sensor_status) && $sensor_status !~ /^(OK)$/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "System Temperator Sensor '" . $sensor_name . "' is " . $sensor_status);
            }
        }
    }
    
    if ($output =~ /^System Indicator Status.*?\n.*?\n.*?\n.*?\n(.*?)\n\n/ims && defined($1)) {
        #MB.LOCATE            MB.SERVICE           MB.ACT
        #--------------------------------------------------------
        #OFF                  OFF                  ON
        
        if ($1 =~ /^([^\s]+)\s+([^\s].*?)\s{2}/) {
            my $mbservice_status = defined($2) ? $2 : undef;
            if (defined($mbservice_status) && $mbservice_status !~ /^(OFF)$/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "System Indicator Status 'MB.SERVICE' is " . $mbservice_status);
            }
        }
    }
    
    if ($output =~ /^Front Status Panel.*?\n.*?\n(.*?)\n\n/ims && defined($1)) {
        # Keyswitch position: NORMAL
        $1 =~ /^[^:]+:\s+([^\s]+)$/;
        if ($1 !~ /normal/i) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Front Statut Panel is '" . $1 . "'");
        }
    }
    
    if ($output =~ /^System Disks.*?\n.*?\n.*?\n.*?\n(.*?)\n\n/ims && defined($1)) {
        #Disk   Status            Service  OK2RM
        #--------------------------------------------
        #HDD0   OK                OFF      OFF
        #HDD1   NOT PRESENT       OFF      OFF
        
        foreach (split(/\n/, $1)) {
            next if (! /^([^\s]+)\s+([^\s].*?)\s{2}/);
            my $disk_status = defined($2) ? $2 : undef;
            my $disk_name = defined($1) ? $1 : undef;
            if (defined($disk_status) && $disk_status !~ /^(OK|NOT PRESENT)$/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Disk Status '" . $disk_name . "' is " . $disk_status);
            }
        }
    }

    if ($output =~ /^Fans.*?\n.*?\n.*?\n.*?\n(.*?)\n\n/ims && defined($1)) {
        #Sensor           Status           Speed   Warn    Low
        #----------------------------------------------------------
        #F0.RS            OK               14062     --   1000
        #F1.RS            OK               14062     --   1000

        foreach (split(/\n/, $1)) {
            next if (! /^([^\s]+)\s+([^\s].*?)\s{2}/);
            my $fan_status = defined($2) ? $2 : undef;
            my $fan_name = defined($1) ? $1 : undef;
            if (defined($fan_status) && $fan_status !~ /^(OK)$/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Fan Sensor Status '" . $fan_name . "' is " . $fan_status);
            }
        }
    }
    
    if ($output =~ /^Voltage sensors.*?\n.*?\n.*?\n.*?\n(.*?)\n\n/ims && defined($1)) {
        #Sensor         Status       Voltage LowSoft LowWarn HighWarn HighSoft
        #--------------------------------------------------------------------------------
        #MB.P0.V_CORE   OK             1.47      --    1.26    1.54       --
        #MB.P1.V_CORE   OK             1.47      --    1.26    1.54       --

        foreach (split(/\n/, $1)) {
            next if (! /^([^\s]+)\s+([^\s].*?)\s{2}/);
            my $voltage_status = defined($2) ? $2 : undef;
            my $voltage_name = defined($1) ? $1 : undef;
            if (defined($voltage_status) && $voltage_status !~ /^(OK)$/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Voltage Sensor status '" . $voltage_name . "' is " . $voltage_status);
            }
        }
    }
    
    if ($output =~ /^Power Supplies.*?\n.*?\n.*?\n.*?\n(.*?)\n\n/ims && defined($1)) {
        #Supply  Status          Underspeed  Overtemp  Overvolt  Undervolt  Overcurrent
        #------------------------------------------------------------------------------
        #PS0     OK              OFF         OFF       OFF       OFF        OFF

        foreach (split(/\n/, $1)) {
            next if (! /^([^\s]+)\s+([^\s].*?)(\s{2}|$)/);
            my $ps_status = defined($2) ? $2 : undef;
            my $ps_name = defined($1) ? $1 : undef;
            if (defined($ps_status) && $ps_status !~ /^(OK)$/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Power Supplies Sensor Status '" . $ps_name . "' is " . $ps_status);
            }
        }
    }
    
    if ($output =~ /^Current sensors.*?\n.*?\n.*?\n.*?\n(.*?)\n\n/ims && defined($1)) {
        #Sensor          Status
        #----------------------
        #MB.FF_SCSI       OK

        foreach (split(/\n/, $1)) {
            next if (! /^([^\s]+)\s+([^\s].*?)(\s{2}|$)/);
            my $sensor_status = defined($2) ? $2 : undef;
            my $sensor_name = defined($1) ? $1 : undef;
            if (defined($sensor_status) && $sensor_status !~ /^(OK)$/i) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Current Sensor status '" . $sensor_name . "' is " . $sensor_status);
            }
        }
    }
    
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Sun vXXX (v240, v440, v245,...) Hardware (through ALOM).

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

=item B<--command-plink>

Plink command (default: plink). Use to set a path.

=item B<--ssh>

Use ssh (with plink) instead of telnet.

=back

=cut
