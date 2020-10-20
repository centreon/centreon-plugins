#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package centreon::common::powershell::exchange::2010::queues;

use strict;
use warnings;
use centreon::common::powershell::exchange::2010::powershell;
use centreon::common::powershell::functions;

sub get_powershell {
    my (%options) = @_;
    
    my $ps = centreon::common::powershell::exchange::2010::powershell::powershell_init(%options);
    $ps .= centreon::common::powershell::functions::escape_jsonstring(%options);
    $ps .= centreon::common::powershell::functions::convert_to_json(%options);
    
    $ps .= '
try {
    $ErrorActionPreference = "Stop"    
    $results = Get-Queue
} catch {
    Write-Host $Error[0].Exception
    exit 1
}

$items = New-Object System.Collections.Generic.List[Hashtable];
Foreach ($result in $results) {
    $item = @{}

    $item.identity = $result.Identity.ToString().Replace("\\", "/")
    $item.nexthopdomain = $result.NextHopDomain
    $item.delivery_type = $result.DeliveryType.value__
    $item.status = $result.Status.value__
    $item.is_valid = $result.IsValid
    $item.message_count = $result.MessageCount
    $item.last_error = $result.LastError
    $items.Add($item)
}

$jsonString = $items | ConvertTo-JSON-20 -forceArray $true
Write-Host $jsonString
exit 0
';

    return $ps;
}

1;

__END__

=head1 DESCRIPTION

Method to check Exchange 2010 queues.

=cut
