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

package centreon::common::powershell::exchange::2010::databases;

use strict;
use warnings;
use centreon::plugins::misc;

sub get_powershell {
	my (%options) = @_;
	# options: no_ps, no_mailflow, no_mapi
	my $no_mailflow = (defined($options{no_mailflow})) ? 1 : 0;
	my $no_ps = (defined($options{no_ps})) ? 1 : 0;
	my $no_mapi = (defined($options{no_mapi})) ? 1 : 0;
	
	return '' if ($no_ps == 1);
	
	my $ps = '
$culture = new-object "System.Globalization.CultureInfo" "en-us"	
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture

If (@(Get-PSSnapin -Registered | Where-Object {$_.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010"} ).count -eq 1) {
	If (@(Get-PSSnapin | Where-Object {$_.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010"} ).count -eq 0) {
		Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
	} else {
		Write-Host "Snap-In no present or not registered"
		exit 1
	}
} else {
	Write-Host "Snap-In no present or not registered"
	exit 1
}
$ProgressPreference = "SilentlyContinue"

# Check to make sure all databases are mounted
$MountedDB = Get-MailboxDatabase -Status

$Status = "Yes"
Foreach ($DB in $MountedDB) {
	Write-Host "[name=" $DB.Name "][server=" $DB.Server "][mounted=" $DB.Mounted "]" -NoNewline
	
	If ($DB.Mounted -eq $true) {
';

	if ($no_mapi == 0) {
		$ps .= '
		# Test Mapi Connectivity
		$MapiResult = test-mapiconnectivity -Database $DB.Name
		Write-Host "[mapi=" $MapiResult.Result "]" -NoNewline
';
	}
	
	if ($no_mailflow == 0) {
		$ps .= '
		# Test Mailflow
		$MailflowResult = Test-mailflow -Targetdatabase $DB.Name
		Write-Host "[mailflow=" $MailflowResult.testmailflowresult "][latency=" $MailflowResult.MessageLatencyTime "]" -NoNewline
';
	}

	$ps .= '
		}
	Write-Host ""
}

exit 0
';

	return centreon::plugins::misc::powershell_encoded($ps);
}

sub check {
	my ($self, %options) = @_;
	# options: stdout
	
	# Following output:
	#[name= Mailbox Database 0975194476 ][server= SRVI-WIN-TEST ][mounted= True ][mapi= Success ][mailflow= Success ][latency= 00:00:01.7949277 ]
	#...
	
	$self->{output}->output_add(severity => 'OK',
                                short_msg => $options{stdout});
}

1;

__END__

=head1 DESCRIPTION

Method to check Exchange 2010 databases.

=cut