#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package centreon::common::powershell::hyperv::2012::nodevmstatus;

use strict;
use warnings;
use centreon::plugins::misc;

sub get_powershell {
    my (%options) = @_;
    my $no_ps = (defined($options{no_ps})) ? 1 : 0;
    
    return '' if ($no_ps == 1);

    my $ps = '
$culture = new-object "System.Globalization.CultureInfo" "en-us"    
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
$ProgressPreference = "SilentlyContinue"

Try {
    $ErrorActionPreference = "Stop"
    $vms = Get-VM

    $node_is_clustered = 0
    Try {
        If (@(Get-ClusterNode -ea Ignore).Count -ne 0) {
            $node_is_clustered = 1
        }
    } Catch {
    }   
    Foreach ($vm in $vms) {
        $note = $vm.Notes -replace "\r",""
        $note = $note -replace "\n"," - "
        $isClustered = $vm.IsClustered
        if ($node_is_clustered -eq 0) {
            $isClustered = "nodeNotClustered"
        }
        Write-Host "[name=" $vm.VMName "][state=" $vm.State "][status=" $vm.Status "][IsClustered=" $isClustered "][note=" $note "]"
    }
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

Method to get hyper-v informations.

=cut
