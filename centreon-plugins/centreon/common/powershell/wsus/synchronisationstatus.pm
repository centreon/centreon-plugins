#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package centreon::common::powershell::wsus::synchronisationstatus;

use strict;
use warnings;
use centreon::common::powershell::functions;

sub get_powershell {
    my (%options) = @_;
    my $no_ps = (defined($options{no_ps})) ? 1 : 0;
    
    return '' if ($no_ps == 1);

    my $ps = '
$culture = new-object "System.Globalization.CultureInfo" "en-us"    
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
';

    $ps .= centreon::common::powershell::functions::escape_jsonstring(%options);
    $ps .= centreon::common::powershell::functions::convert_to_json(%options);

    $ps .= '
$wsusServer = "' . $options{wsus_server} . '"
$useSsl = ' . $options{use_ssl} . '
$wsusPort = ' . $options{wsus_port} . '

Try {
    [void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") 
} Catch {
    Write-Host $Error[0].Exception
    exit 1
}

$ProgressPreference = "SilentlyContinue"

Try {
    $ErrorActionPreference = "Stop"

    $wsusObject = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($wsusServer, $useSsl, $wsusPort)

    $syncStatus = $wsusObject.GetSubscription().GetSynchronizationStatus()
    $syncProgress = $wsusObject.GetSubscription().GetSynchronizationProgress()
    $lastSync = $wsusObject.GetSubscription().GetLastSynchronizationInfo()
        
    $returnObject = New-Object -TypeName PSObject
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "SynchronizationStatus" -Value $syncStatus.ToString()
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "TotalItems" -Value $syncProgress.TotalItems
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ProcessedItems" -Value $syncProgress.ProcessedItems
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "LastSynchronizationResult" -Value $lastSync.Result.ToString()
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "LastSynchronizationStartTime" -Value $lastSync.StartTime
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "LastSynchronizationEndTime" -Value $lastSync.EndTime
    
    $jsonString = $returnObject | ConvertTo-JSON-20
    Write-Host $jsonString
} Catch {
    Write-Host $Error[0].Exception
    exit 1
}

exit 0
';

    return centreon::plugins::misc::powershell_encoded($ps);
}

1;

__END__

=head1 DESCRIPTION

Method to get WSUS synchronisation informations.

=cut
