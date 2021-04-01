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

package centreon::common::powershell::hyperv::2012::nodesnapshot;

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
    $vms = Get-VM
    if ($vms.Length -gt 0) {
        $snapshots = Get-VMSnapshot -VMName *
    }

    $items = New-Object System.Collections.Generic.List[Hashtable];
    Foreach ($vm in $vms) {
        $item = @{}

        $note = $vm.Notes -replace "\r",""
        $note = $note -replace "\n"," - "
        $item.note = $note
        $item.name = $vm.VMName
        $item.state = $vm.State.value__

        $checkpoints = New-Object System.Collections.Generic.List[Hashtable];
        Foreach ($snap in $snapshots) {
            if ($snap.VMName -eq $vm.VMName) {
                $checkpoint = @{}
                $checkpoint.type = "snapshot"
                $checkpoint.creation_time = (get-date -date $snap.CreationTime.ToUniversalTime() -UFormat ' . "'%s'" . ')
                $checkpoints.Add($checkpoint)
            }
        }
        if ($vm.status -imatch "Backing") {
            $VMDisks = Get-VMHardDiskDrive -VMName $vm.VMName
            Foreach ($VMDisk in $VMDisks) {
                $VHD = Get-VHD $VMDisk.Path
                if ($VHD.Path -imatch ".avhdx" -or $VHD.VhdType -imatch "Differencing") {
                    $checkpoint = @{}
                    $parent = Get-Item $VHD.ParentPath
                    $checkpoint.type = "backing"
                    $checkpoint.creation_time = (get-date -date $parent.LastWriteTime.ToUniversalTime() -UFormat ' . "'%s'" . ')
                    $checkpoints.Add($checkpoint)
                }
            }
        }

        $item.checkpoints = $checkpoints
        $items.Add($item)
    }

    $jsonString = $items | ConvertTo-JSON-20 -forceArray $true
    Write-Host $jsonString
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

Method to get hyper-v informations.

=cut
