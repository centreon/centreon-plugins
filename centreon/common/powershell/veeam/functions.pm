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

package centreon::common::powershell::veeam::functions;

use strict;
use warnings;

sub powershell_init {
    my (%options) = @_;
    
    my $ps = '
$register_snaps=Get-PSSnapin -Registered
$all_snaps=Get-PSSnapin
$load_snaps=@("VeeamPSSnapin")
$registered=0
foreach ($snap_name in $load_snaps) {
    if (@($register_snaps | Where-Object {$_.Name -Match $snap_name} ).count -gt 0) {
        if (@($all_snaps | Where-Object {$_.Name -Match $snap_name} ).count -eq 0) {
            Try {
                $register_snaps | Where-Object {$_.Name -Match $snap_name} | Add-PSSnapin -ErrorAction STOP
                $registered=1
            } Catch {
                Write-Host $Error[0].Exception
                exit 1
            }
        }
    }
}
if ($registered -eq 0) {
    if (@(Get-Module | Where-Object {$_.Name -Match "Veeam.Backup.PowerShell"} ).count -eq 0) {
        Try {
            Import-Module -DisableNameChecking -Name "Veeam.Backup.PowerShell"
            $registered=1
        } Catch {
            Write-Host $Error[0].Exception
            exit 1
        }
    }
    if ($registered -eq 0) {
        Write-Host "Snap-In/Module Veeam no present or not registered"
        exit 1
    }
}
';

    return $ps;
}

1;

__END__

=head1 DESCRIPTION

Powershell commands

=cut
