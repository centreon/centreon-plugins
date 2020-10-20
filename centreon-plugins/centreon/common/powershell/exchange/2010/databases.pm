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

package centreon::common::powershell::exchange::2010::databases;

use strict;
use warnings;
use centreon::common::powershell::exchange::2010::powershell;
use centreon::common::powershell::functions;

sub get_powershell {
    my (%options) = @_;
    # options: no_mailflow, no_mapi
    my $no_mailflow = (defined($options{no_mailflow})) ? 1 : 0;
    my $no_mapi = (defined($options{no_mapi})) ? 1 : 0;
    my $no_copystatus = (defined($options{no_copystatus})) ? 1 : 0;

    my $ps = centreon::common::powershell::exchange::2010::powershell::powershell_init(%options);
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

    $item.database = $DB.Name
    $item.server = $DB.Server.Name
    $item.mounted = $DB.Mounted
    $item.size = $DB.DatabaseSize.ToBytes().ToString()
    $item.asize = $DB.AvailableNewMailboxSpace.ToBytes().ToString()
';
    
    if (defined($options{filter_database_test}) && $options{filter_database_test} ne '') {
        $ps .= '
        if (!($DB.Name -match "' . $options{filter_database_test} . '")) {
            continue
        }
';
    }
    
    $ps .= '
        If ($DB.Mounted -eq $true) {
';

    if ($no_mapi == 0) {
        $ps .= '
            # Test Mapi Connectivity
            $MapiResult = test-mapiconnectivity -Database $DB.Name
            $item.mapi_result = $MapiResult.Result
';
    }
    
    if ($no_mailflow == 0) {
        $ps .= '
            # Test Mailflow
            $MailflowResult = Test-mailflow -Targetdatabase $DB.Name
            $item.mailflow_result = $MailflowResult.testmailflowresult
            $item.mailflow_latency = $MailflowResult.MessageLatencyTime.TotalMilliseconds
';
    }
    if ($no_copystatus == 0) {
        $ps .= '
            # Test CopyStatus
            $tmp_name = $DB.Name + "\" + $DB.Server
            $CopyStatusResult = Get-MailboxDatabaseCopyStatus -Identity $tmp_name
            $item.copystatus_indexstate = $CopyStatusResult.ContentIndexState.value__
            $item.copystatus_content_index_error_message = $CopyStatusResult.ContentIndexErrorMessage
';
    }

    $ps .= '
        }

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

Method to check Exchange 2010 databases.

=cut
