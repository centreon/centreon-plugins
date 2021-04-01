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

package centreon::common::powershell::dell::compellent::hbausage;

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

Function display_hba_information {
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
    $historical = New-DellHistoricalFilter -FilterTime "Other" -StartTime "' . $options{start_time} . '" -EndTime "' . $options{end_time} . '"
    foreach ($sc in $storageCenters) {
        $hbaList = Get-DellScServerHba -ConnectionName $connName -StorageCenter $sc
        
        foreach ($hba in $hbaList) {
            $usageList = Get-DellScServerHbaHistoricalIoUsage -ConnectionName $connName -Instance $hba -HistoricalFilter $historical
            
            write-host ("[sc={0}]" -f $hba.ScName) -NoNewline
            write-host ("[name={0}]" -f $hba.Name) -NoNewline
            
            $attrs = @{ReadKbPerSecond = 0; WriteKbPerSecond = 0; ReadIops = 0; WriteIops = 0; ReadLatency = 0; WriteLatency = 0; }
            $count = 0
            foreach ($usage in $usageList)  {
                foreach ($item in $($attrs.GetEnumerator() | sort -Property Key)) {
                    $attrs[$item.Key] += ($usage | Select -ExpandProperty $item.Key)
                }
                $count++
            }
            
            foreach ($item in $attrs.GetEnumerator() | sort -Property Key) {
                write-host ("[{0}={1}]" -f $item.Key, ($item.Value / $count)) -NoNewline
            }
            write-host
        }
    }
}

Try {
    Import-Module "' . $options{sdk_path_dll} . '"
    display_hba_information
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

Method to get compellent hba informations.

=cut
