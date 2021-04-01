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

package centreon::common::powershell::sccm::databasereplicationstatus;

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

    $CMObject = Get-CMDatabaseReplicationStatus

    CD "C:\"
    Remove-PSDrive -Name SCCMDrive
    
    $returnObject = New-Object -TypeName PSObject
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "LinkStatus" -Value $CMObject.LinkStatus

    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Site1" -Value $CMObject.Site1
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "SiteName1" -Value $CMObject.SiteName1
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "SiteType1" -Value $CMObject.SiteType1
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Site1Status" -Value $CMObject.Site1Status

    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Site2" -Value $CMObject.Site2
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "SiteName2" -Value $CMObject.SiteName2
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "SiteType2" -Value $CMObject.SiteType2
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Site2Status" -Value $CMObject.Site2Status

    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Site1ToSite2GlobalState" -Value $CMObject.Site1ToSite2GlobalState
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Site1ToSite2GlobalSyncTime" -Value $CMObject.Site1ToSite2GlobalSyncTime
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Site2ToSite1GlobalState" -Value $CMObject.Site2ToSite1GlobalState
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Site2ToSite1GlobalSyncTime" -Value $CMObject.Site2ToSite1GlobalSyncTime
    
    $returnObject | ConvertTo-JSON-20
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
