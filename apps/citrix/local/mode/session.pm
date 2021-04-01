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

package apps::citrix::local::mode::session;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Win32::OLE;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'warning:s'     => { name => 'warning' },
        'critical:s'    => { name => 'critical' },
        'domain:s'      => { name => 'domain' },
        'filter-domain' => { name => 'filter_domain' },
        'farm:s'        => { name => 'farm' },
        'filter-farm'   => { name => 'filter_farm' },
        'server:s'      => { name => 'server' },
        'filter-server' => { name => 'filter_server' },
        'zone:s'        => { name => 'zone' },
        'filter-zone'   => { name => 'filter_zone' }
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
    
    $self->{output}->output_add(
        severity => 'Ok',
        short_msg => 'All sessions are ok'
    );

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
        $self->{output}->perfdata_add(
            label => 'active_sessions',
            nlabel => 'sessions.active.count',
            instances => $server,
            value => $activeSessions,
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
            min => 0
        );
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
