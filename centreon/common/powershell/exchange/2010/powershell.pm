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
#	    Frank Holtz <f.holtz@scitech-gmbh.de>
#
####################################################################################

package centreon::common::powershell::exchange::2010::powershell;

use strict;
use warnings;
use centreon::plugins::misc;

# Generate Scipt to Load exchange extensions
#--remote-host --remote-user --remote-password
sub powershell_init {
    my (%options) = @_;
    # options: no_ps
    my $no_ps = (defined($options{no_ps})) ? 1 : 0;
    
    return '' if ($no_ps == 1);
    
    my $ps = '
$culture = new-object "System.Globalization.CultureInfo" "en-us"    
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
';

    if (!defined($options{remote_host})) {
        $ps.='
    If (@(Get-PSSnapin -Registered | Where-Object {$_.Name -Match "Microsoft.Exchange.Management.PowerShell.E"} ).count -gt 0) {
    If (@(Get-PSSnapin | Where-Object {$_.Name -Match "Microsoft.Exchange.Management.PowerShell.E"} ).count -eq 0) {
        Try {
            Get-PSSnapin -Registered | Where-Object {$_.Name -Match "Microsoft.Exchange.Management.PowerShell.E"} | Add-PSSnapin -ErrorAction STOP
        } Catch {
            Write-Host $Error[0].Exception
            exit 1
        }
    } else {
        Write-Host "Snap-In no present or not registered"
        exit 1
    }
} else {
    Write-Host "Snap-In no present or not registered"
    exit 1
}
$ProgressPreference = "SilentlyContinue"
';
    } else {
        # Find exchange installation path
        my $exchangepath;
        if (defined($ENV{ExchangeInstallPath})) {
            # Windows Variable
            $exchangepath = $ENV{ExchangeInstallPath};
        } else {
            # No ENV -> look into registry (access via cygwin ssh session)
            my $filename = "/proc/registry/HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Session Manager/Environment/ExchangeInstallPath";
            if (-e $filename) {
                open FILE, "$filename" or die "Couldn't open file: $!";
                $exchangepath = <FILE>;
                $exchangepath =~ s/[\r|\n|\0].*//g;
                close FILE;
            }
        }

        # No installation found
        if (!defined($exchangepath)) {
            print '$ENV{ExchangeInstallPath} is undefined. Please install PowerShell extensions for Exchange.';
            exit 1
        }

        $ps .= '
# Open a session to the exchange
try
{
    $ErrorActionPreference = "Stop"
    . "'.$exchangepath.'\bin\RemoteExchange.ps1"
} catch {
   Write-Host $Error[0].Exception
    exit 1
}
try
{
    $ErrorActionPreference = "Stop"';

        if (defined($options{remote_user}) && defined($options{remote_password})) {
            # Replace / to \
            $options{remote_user}=~ s/\//\\/g;
            $ps .= '
    $username = "'.centreon::plugins::misc::powershell_escape($options{remote_user}) . '"
    $password = ConvertTo-SecureString "' . centreon::plugins::misc::powershell_escape($options{remote_password}) . '" -AsPlainText -Force
    $UserCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist $username,$password
    Connect-ExchangeServer -ServerFqdn "'. centreon::plugins::misc::powershell_escape($options{remote_host}) .'" -UserName $UserCredential
        ';
        } else {
            $ps .= '
    Connect-ExchangeServer -ServerFqdn "'. centreon::plugins::misc::powershell_escape($options{remote_host}) .'"
    ';
        }
        $ps .= '
} catch {
    Write-Host $Error[0].Exception
    exit 1
  }
';
    }
	
    return $ps;
}

1;

__END__

=head1 DESCRIPTION

Powershell commands

=cut