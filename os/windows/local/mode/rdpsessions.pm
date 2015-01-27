################################################################################
# Copyright 2005-2014 MERETHIS
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

package os::windows::local::mode::rdpsessions;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Win32::OLE;
use DateTime;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning-inactive:s"      => { name => 'warning_inactive' },
                                  "critical-inactive:s"     => { name => 'critical_inactive' },
                                  "warning-active:s"        => { name => 'warning_active' },
                                  "critical-active:s"       => { name => 'critical_active' },
                                  "warning-time:s"          => { name => 'warning_time' },
                                  "critical-time:s"         => { name => 'critical_time' },
                                });
    $self->{os_is2003} = 0;
    $self->{os_is2008} = 0;
    $self->{os_is2012} = 0;
    $self->{result_sessions} = {};
    $self->{result_detailed} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach my $label (('warning_inactive', 'critical_inactive', 'warning_active', 'critical_active', 'warning_time', 'critical_time')) {
        if (($self->{perfdata}->threshold_validate(label => $label, value => $self->{option_results}->{$label})) == 0) {
            my ($label_opt) = $label;
            $label_opt =~ tr/_/-/;
            $self->{output}->add_option_msg(short_msg => "Wrong " . $label_opt . " threshold '" . $self->{option_results}->{$label} . "'.");
            $self->{output}->option_exit();
        }
    }
}

sub check_version {
    my ($self, %options) = @_;

    my ($ver_string, $ver_major, $ver_minor, $ver_build, $ver_id) = Win32::GetOSVersion();    
    #"Operating system is " . "$ver_string - ($ver_id.$ver_major.$ver_minor.$ver_build)\n";
    
    # 5.1, 5.2 => XP/2003
    # 6.0, 6.1 => Vista/7/2008
    # 6.2, 6.3 => 2012
    if ($ver_major == 5 && ($ver_minor == 1 || $ver_minor == 2)) {
        $self->{os_is2003} = 1;
    } elsif ($ver_major == 6 && ($ver_minor == 0 || $ver_minor == 1)) {
        $self->{os_is2008} = 1;
    } elsif ($ver_major == 6 && ($ver_minor == 2 || $ver_minor == 3)) {
        $self->{os_is2012} = 1;
    } else {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'OS version ' . $ver_major . '.' . $ver_minor . ' not managed.');
        return 1;
    }
    return 0;
}

sub get_sessions {
    my ($self, %options) = @_;
    
    $self->{wmi} = Win32::OLE->GetObject('winmgmts:root\CIMV2');
    if (!defined($self->{wmi})) {
        $self->{output}->add_option_msg(short_msg => "Cant create server object:" . Win32::OLE->LastError());
        $self->{output}->option_exit();
    }
    my $query = 'SELECT ActiveSessions, InactiveSessions FROM Win32_PerfRawData_LocalSessionManager_TerminalServices';
    if ($self->{os_is2003} == 1) {
        $query = 'SELECT ActiveSessions, InactiveSessions FROM Win32_PerfRawData_TermService_TerminalServices ';
    }
    my $resultset = $self->{wmi}->ExecQuery($query);
    foreach my $obj (in $resultset) {
        $self->{result_sessions}->{active_sessions} = $obj->{ActiveSessions};
        if ($self->{os_is2003} == 1) {
            $self->{result_sessions}->{inactive_sessions} = $obj->{InactiveSessions} - 1; # Console session
        } else {
            $self->{result_sessions}->{inactive_sessions} = $obj->{InactiveSessions} - 2; # Service and Console sessions
        }
    }
}

sub get_detailed_informations {
    my ($self, %options) = @_;
    
    my $query = 'SELECT LogonId, StartTime FROM Win32_LogonSession WHERE LogonType = 10';
    my $resultset = $self->{wmi}->ExecQuery($query);
    foreach my $obj (in $resultset) {
        my $resultset2 = $self->{wmi}->ExecQuery('Associators of {Win32_LogonSession.LogonId=' . 
                                                  $obj->{LogonId} . '} Where AssocClass=Win32_LoggedOnUser Role=Dependent');
        foreach my $obj2 (in $resultset2) {
            $obj->{StartTime} =~ /^([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})\.[0-9]+([+\-])(.*)/;
            my ($year, $month, $day, $hour, $min, $sec, $tz, $tz_min) = ($1, $2, $3, $4, $5, $6, $7, $8);
            my $tz_time = sprintf("%02d%02d", $tz_min / 60, $tz_min % 60);
            my $dt = DateTime->new(
                year       => $year,
                month      => $month,
                day        => $day,
                hour       => $hour,
                minute     => $min,
                second     => $sec,
                time_zone  => $tz . $tz_time,
            );
            
            $self->{result_detailed}->{$obj2->{Domain} . '\\' . $obj2->{Name}} = $dt->epoch;
        }
    }    
}

sub manage {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_sessions}->{active_sessions}, threshold => [ { label => 'critical_active', exit_litteral => 'critical' }, { label => 'warning_active', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("%d active session(s)", $self->{result_sessions}->{active_sessions}));
    $exit = $self->{perfdata}->threshold_check(value => $self->{result_sessions}->{inactive_sessions}, threshold => [ { label => 'critical_inactive', exit_litteral => 'critical' }, { label => 'warning_inactive', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("%d inactive session(s)", $self->{result_sessions}->{inactive_sessions}));

    foreach my $user (sort keys %{$self->{result_detailed}}) {
        $exit = $self->{perfdata}->threshold_check(value => time() - $self->{result_detailed}->{$user}, threshold => [ { label => 'critical_time', exit_litteral => 'critical' }, { label => 'warning_time', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(long_msg => sprintf("User %s session opened since %s", $user,  scalar(localtime($self->{result_detailed}->{$user}))));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("User %s session opened since %s", $user, scalar(localtime($self->{result_detailed}->{$user}))));
        }
    }
                                
    $self->{output}->perfdata_add(label => 'active_sessions',
                                  value => $self->{result_sessions}->{active_sessions},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_active'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_active'),
                                  min => 0, max => $self->{result_sessions}->{active_sessions} + $self->{result_sessions}->{inactive_sessions});
    $self->{output}->perfdata_add(label => 'inactive_sessions',
                                  value => $self->{result_sessions}->{inactive_sessions},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_inactive'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_inactive'),
                                  min => 0, max => $self->{result_sessions}->{active_sessions} + $self->{result_sessions}->{inactive_sessions});
}

sub run {
    my ($self, %options) = @_;
    
    if ($self->check_version() == 0) {
        $self->get_sessions();
        $self->get_detailed_informations();
        $self->manage();
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check rdp sessions.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'inactive', 'active', 'time' (in seconds since the session starts).

=item B<--critical-*>

Threshold critical.
Can be: 'inactive', 'active', 'time' (in seconds since the session starts).

=back

=cut