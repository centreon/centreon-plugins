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

package centreon::common::powershell::dell::compellent::volumeusage;

use strict;
use warnings;

sub get_powershell {
    my (%options) = @_;

    my $ps = '
$culture = new-object "System.Globalization.CultureInfo" "en-us"    
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

$scuser = "' . $options{cem_user} . '"
$scpass = ConvertTo-SecureString "' . $options{cem_password} . '" -AsPlainText -Force
$schost = "' . $options{cem_host} . '"
$scport = "'  . $options{cem_port} . '"
$connName = "EMDefault"

Function display_volume_information {
    $conn = Connect-DellApiConnection -HostName $schost -Port $scport -User $scuser -password $scpass -Save $connName
';
    if (defined($options{filter_sc}) && $options{filter_sc} ne '') {
        $ps .= '$storageCenters = Get-DellStorageCenter -ConnectionName $connName -Name "' . $options{filter_sc} . '"
';
    } else {
        $ps .= '$storageCenters = Get-DellStorageCenter -ConnectionName $connName
';
    }
    
    $ps .= '    
    foreach ($sc in $storageCenters) {
        $volumeList = Get-DellScVolume -ConnectionName $connName -StorageCenter $sc
        foreach ($vol in $volumeList) {
';
    if (defined($options{filter_vol}) && $options{filter_vol} ne '') {
        $ps .= 'if (-Not ($vol -match "' . $options{filter_vol} . '")) { continue }
';
	}
    
    $ps .= '$volusage = Get-DellScVolumeStorageUsageAssociation -ConnectionName $connName -Instance $vol
            $usage = Get-DellScVolumeStorageUsage -ConnectionName $connName -Instance $volusage
            
            write-host ("[sc={0}]" -f $sc.Name) -NoNewline
            write-host ("[volume={0}]" -f $usage.Name) -NoNewline
            write-host ("[configuredSpace={0}]" -f $usage.ConfiguredSpace.GetByteSize()) -NoNewline
            write-host ("[freeSpace={0}]"  -f $usage.FreeSpace.GetByteSize()) -NoNewline
            write-host ("[activeSpace={0}]"  -f $usage.ActiveSpace.GetByteSize()) -NoNewline
            write-host ("[raidOverhead={0}]"  -f $usage.RaidOverhead.GetByteSize()) -NoNewline
            write-host ("[totalDiskSpace={0}]"  -f $usage.TotalDiskSpace.GetByteSize()) -NoNewline
            write-host ("[replaySpace={0}]" -f $usage.replaySpace.GetByteSize())
        }
';
 
    if (defined($options{filter_vol}) && $options{filter_vol} ne '') {
        $ps .= 'continue
';
    }
    
    $ps .= '$diskList = Get-DellScDisk -ConnectionName $connName -StorageCenter $sc
        foreach ($disk in $diskList) {
            $diskusage = Get-DellScDiskStorageUsageAssociation -ConnectionName $connName -Instance $disk
            $usage = Get-DellScDiskStorageUsage -ConnectionName $connName -Instance $diskusage
            write-host ("[sc={0}]" -f $sc.Name) -NoNewline
            write-host ("[disk={0}]" -f $disk.Name) -NoNewline
            write-host ("[spare={0}]" -f  $disk.Spare) -NoNewline
            write-host ("[allocatedSpace={0}]" -f $usage.AllocatedSpace.GetByteSize())
        }
    }
}

Try {
    Import-Module "' . $options{sdk_path_dll} . '"
    display_volume_information
} Catch {
    Write-Host $Error[0].Exception
    $ret = Remove-DellSavedApiConnection -Name $connName
    exit 1
}

$ret = Remove-DellSavedApiConnection -Name $connName
exit 0
';

    return $ps;
}

1;

__END__

=head1 DESCRIPTION

Method to get compellent volume informations.

=cut
