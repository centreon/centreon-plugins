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

package centreon::common::powershell::sccm::sitestatus;

use strict;
use warnings;
use centreon::common::powershell::functions;

sub get_powershell {
    my (%options) = @_;

    my $ps = '
$culture = new-object "System.Globalization.CultureInfo" "en-us"    
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
';

    $ps .= centreon::common::powershell::functions::escape_jsonstring(%options);
    $ps .= centreon::common::powershell::functions::convert_to_json(%options);

    $ps .= '
$ProgressPreference = "SilentlyContinue"

Try {
    $ErrorActionPreference = "Stop"

    $modulePath = ${env:SMS_ADMIN_UI_PATH}
    $modulePath = $modulePath.Substring(0, $modulePath.lastIndexOf("\"))
    $module = $modulePath + "\ConfigurationManager.psd1"
    Import-Module $module

    New-PSDrive -Name SCCMDrive -PSProvider "AdminUI.PS.Provider\CMSite" -Root $env:COMPUTERNAME -Description "SCCM Site" | Out-Null
    CD "SCCMDrive:\"

    $CMObject = Get-CMSite

    CD "C:\"
    Remove-PSDrive -Name SCCMDrive

    $returnArray = @()
    
    Foreach ($site in $CMObject) {
        $returnObject = New-Object -TypeName PSObject
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "SiteCode" -Value $site.SiteCode
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "SiteName" -Value $site.SiteName
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Type" -Value $site.Type
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Mode" -Value $site.Mode
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value $site.Status
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "SecondarySiteCMUpdateStatus" -Value $site.SecondarySiteCMUpdateStatus
        $returnArray += $returnObject
    }
    
    $returnArray | ConvertTo-JSON-20 -forceArray $true
} Catch {
    Write-Host $Error[0].Exception
    exit 1
}

exit 0
';
    return $ps;
}

1;

__END__

=head1 DESCRIPTION

Method to get SCCM database replication informations.

=cut
