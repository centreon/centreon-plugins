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

package centreon::common::powershell::hyperv::2012::nodereplication;

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
    $vms = Get-VMReplication

    $items = New-Object System.Collections.Generic.List[Hashtable];
    Foreach ($vm in $vms) {
        $item = @{}

        $item.name = $vm.Name
        $item.state = $vm.State.value__
        $item.health = $vm.Health.value__
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
