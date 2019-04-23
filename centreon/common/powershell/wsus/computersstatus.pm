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

package centreon::common::powershell::wsus::computersstatus;

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
$notUpdatedSince = ' . $options{not_updated_since} . '

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

    $wsusStatus = $wsusObject.GetStatus()

    $notUpdatedSinceTimespan = new-object TimeSpan($notUpdatedSince, 0, 0, 0)
    $computersNotContactedSinceCount = $wsusObject.GetComputersNotContactedSinceCount([DateTime]::UtcNow.Subtract($notUpdatedSinceTimespan))

    $computerTargetScope = new-object Microsoft.UpdateServices.Administration.ComputerTargetScope
    $unassignedComputersCount = $wsusObject.GetComputerTargetGroup([Microsoft.UpdateServices.Administration.ComputerTargetGroupId]::UnassignedComputers).GetComputerTargets().Count
    
    $returnObject = New-Object -TypeName PSObject
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerTargetsNeedingUpdatesCount" -Value $wsusStatus.ComputerTargetsNeedingUpdatesCount
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerTargetsWithUpdateErrorsCount" -Value $wsusStatus.ComputerTargetsWithUpdateErrorsCount
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputersUpToDateCount" -Value $wsusStatus.ComputersUpToDateCount
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputersNotContactedSinceCount" -Value $computersNotContactedSinceCount
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "UnassignedComputersCount" -Value $unassignedComputersCount
    
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

Method to get WSUS computers informations.

=cut
