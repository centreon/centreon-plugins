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

package apps::citrix::local::mode::session;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Win32::OLE;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"           => { name => 'warning', },
                                  "critical:s"          => { name => 'critical', },
                                  "domain:s"            => { name => 'domain', },
                                  "filter-domain"       => { name => 'filter_domain', },
                                  "farm:s"              => { name => 'farm', },
                                  "filter-farm"         => { name => 'filter_farm', },
                                  "server:s"            => { name => 'server', },
                                  "filter-server"       => { name => 'filter_server', },
                                  "zone:s"              => { name => 'zone', },
                                  "filter-zone"         => { name => 'filter_zone', },
                                });
    $self->{wql_filter} = '';
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{domain})) {
        if (defined($self->{option_results}->{filter_domain})) {
            $self->{wql_filter} .= "Domain like '" . $self->{option_results}->{domain} . "'";
        } else {
            $self->{wql_filter} .= "Domain='" . $self->{option_results}->{domain} . "'";
        }
    } else {
        $self->{wql_filter} .= "Domain like '%'";
    }
    if (defined($self->{option_results}->{farm})) {
        if (defined($self->{option_results}->{filter_farm})) {
            $self->{wql_filter} .= " and FarmName like '" . $self->{option_results}->{farm} . "'";
        } else {
            $self->{wql_filter} .= " and FarmName='" . $self->{option_results}->{farm} . "'";
        }
    } else {
        $self->{wql_filter} .= " and FarmName like '%'";
    }
    if (defined($self->{option_results}->{server})) {
        if (defined($self->{option_results}->{filter_server})) {
            $self->{wql_filter} .= " and ServerName like '" . $self->{option_results}->{server} . "'";
        } else {
            $self->{wql_filter} .= " and ServerName='" . $self->{option_results}->{server} . "'";
        }
    } else {
        $self->{wql_filter} .= " and ServerName like '%'";
    }
    if (defined($self->{option_results}->{zone})) {
        if (defined($self->{option_results}->{filter_zone})) {
            $self->{wql_filter} .= " and ZoneName like '" . $self->{option_results}->{zone} . "'";
        } else {
            $self->{wql_filter} .= " and ZoneName='" . $self->{option_results}->{zone} . "'";
        }
    } else {
        $self->{wql_filter} .= " and ZoneName like '%'";
    }
}

sub run {
    my ($self, %options) = @_;
    
    $self->{output}->output_add(severity => 'Ok',
                                short_msg => "All sessions are ok");
  
    my $wmi = Win32::OLE->GetObject('winmgmts:root\citrix');
    if (!defined($wmi)) {
        $self->{output}->add_option_msg(short_msg => "Cant create server object:" . Win32::OLE->LastError());
        $self->{output}->option_exit();
    }

    my $query = "Select Domain,FarmName,NumberOfActiveSessions,NumberOfDisconnectedSessions,NumberOfSessions,ServerName,ZoneName from MetaFrame_Server where " . $self->{wql_filter};
    my $resultset = $wmi->ExecQuery($query);
    foreach my $obj (in $resultset) {
        my $domain = $obj->{Domain};
        my $farm = $obj->{FarmName};
        my $activeSessions = $obj->{NumberOfActiveSessions};
        my $disconnectedSessions = $obj->{NumberOfDisconnectedSessions};
        my $sessions = $obj->{NumberOfSessions};
        my $server = $obj->{ServerName};
        my $zone = $obj->{ZoneName};

        $self->{output}->output_add(long_msg => "Server '" . $server . "' active sessions : " . $activeSessions . " [disconnected sessions : " . $disconnectedSessions . "] [total sessions : " . $sessions . "] [Domain '" . $domain . "', Farm '" . $farm . "', Zone '" . $zone . "']");
        my $exit = $self->{perfdata}->threshold_check(value => $activeSessions, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Server '" . $server . "' active sessions : " . $activeSessions . " [disconnected sessions : " . $disconnectedSessions . "] [total sessions : " . $sessions . "]");
        }
        $self->{output}->perfdata_add(label => 'active_sessions_' . $server,
                                      value => $activeSessions,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
    }

 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Citrix sessions.

=over 8

=item B<--warning>

Threshold warning of active sessions.

=item B<--critical>

Threshold critical of active sessions.

=item B<--domain>

Specify a domain.

=item B<--filter-domain>

Use like request in WQL for domain (use with --domain).

=item B<--farm>

Specify a farm name.

=item B<--filter-farm>

Use like request in WQL for farm name (use with --farm).

=item B<--server>

Specify a server name.

=item B<--filter-server>

Use like request in WQL for server name (use with --server).

=item B<--zone>

Specify a zone.

=item B<--filter-zone>

Use like request in WQL for zone (use with --zone).

=back

=cut
