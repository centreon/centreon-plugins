#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package centreon::common::powershell::exchange::listdatabases;

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::exchange::powershell;
use centreon::common::powershell::functions;

sub get_powershell {
    my (%options) = @_;
    
    my $ps = centreon::common::powershell::exchange::powershell::powershell_init(%options);
    $ps .= centreon::common::powershell::functions::escape_jsonstring(%options);
    $ps .= centreon::common::powershell::functions::convert_to_json(%options);
    
    $ps .= '
# Check to make sure all databases are mounted
try { 
    $ErrorActionPreference = "Stop"
';

    if (defined($options{filter_database})) {
        $ps .= '
    $MountedDB = Get-MailboxDatabase -Identity "' . $options{filter_database} . '" -Status
';
    } else {
        $ps .= '
    $MountedDB = Get-MailboxDatabase -Status
';
    }

    $ps .= '
} catch {
    Write-Host $Error[0].Exception
    exit 1
}

$items = New-Object System.Collections.Generic.List[Hashtable];
Foreach ($DB in $MountedDB) {
    $item = @{}
    $item.name = $DB.Name
    $item.server = $DB.Server.Name
    $item.mounted = $DB.Mounted
    $item.size = $DB.DatabaseSize.ToBytes().ToString()
    $item.asize = $DB.AvailableNewMailboxSpace.ToBytes().ToString()
    $items.Add($item)
';
    $ps .= '
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

Method to list Exchange databases.

=cut
