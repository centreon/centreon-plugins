#
# Copyright 2017 Centreon (http://www.centreon.com/)
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