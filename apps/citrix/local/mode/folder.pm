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

package apps::citrix::local::mode::folder;

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
                                  "folder:s"            => { name => 'folder', },
                                  "filter-folder"       => { name => 'filter_folder', },
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
    if (defined($self->{option_results}->{folder})) {
        if (defined($self->{option_results}->{filter_folder})) {
            $self->{wql_filter} .= " FolderDN like '" . $self->{option_results}->{folder} . "'";
        } else {
            $self->{wql_filter} .= " FolderDN='" . $self->{option_results}->{folder} . "'";
        }
    } else {
        $self->{wql_filter} .= " FolderDN like '%'";
    }
}

sub run {
    my ($self, %options) = @_;
    
    $self->{output}->output_add(severity => 'Ok',
                                short_msg => "All folders are ok");
  
    my $wmi = Win32::OLE->GetObject('winmgmts:root\citrix');
    if (!defined($wmi)) {
        $self->{output}->add_option_msg(short_msg => "Cant create server object:" . Win32::OLE->LastError());
        $self->{output}->option_exit();
    }

    my $query = "Select FolderDN from Citrix_ServerFolder where " . $self->{wql_filter};
    my $resultset = $wmi->ExecQuery($query);
    foreach my $obj (in $resultset) {
        my $folderDN = $obj->{FolderDN};
        my $query2 = "ASSOCIATORS OF {Citrix_ServerFolder.FolderDN='" . $folderDN . "'} WHERE AssocClass=Citrix_ServersInFolder Role=Antecedent";
        my $resultset2 = $wmi->ExecQuery($query2);
        my $numServers = keys $resultset2;
        $self->{output}->output_add(long_msg => $numServers . " servers in folder '" . $folderDN . "'");
        my $exit = $self->{perfdata}->threshold_check(value => $numServers, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => $numServers . " servers in in folder '" . $folderDN . "'");
        }
        $self->{output}->perfdata_add(label => 'servers_' . $folderDN,
                                      value => $numServers,
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

Check Citrix servers per folder.

=over 8

=item B<--warning>

Threshold warning of servers per folder.

=item B<--critical>

Threshold critical of servers per folder.

=item B<--folder>

Specify a folder.

=item B<--filter-folder>

Use like request in WQL for folder (use with --folder).

=back

=cut
