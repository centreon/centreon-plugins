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

package centreon::common::powershell::exchange::powershell;

use strict;
use warnings;
use centreon::plugins::misc;

# Generate Scipt to Load exchange extensions
#--remote-host --remote-user --remote-password
sub powershell_init {
    my (%options) = @_;
    
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
