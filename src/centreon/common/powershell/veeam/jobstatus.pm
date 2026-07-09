#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package centreon::common::powershell::veeam::jobstatus;

use strict;
use warnings;
use centreon::common::powershell::functions;
use centreon::common::powershell::veeam::functions;

use Exporter 'import';

use constant {
    VEEAM_JOB_SOURCE_ALL => 'all',
    VEEAM_JOB_SOURCE_STANDARD => 'standard',
    VEEAM_JOB_SOURCE_AGENT => 'agent',
};

our %EXPORT_TAGS = (
    job_source => [ qw(VEEAM_JOB_SOURCE_ALL
                       VEEAM_JOB_SOURCE_STANDARD
                       VEEAM_JOB_SOURCE_AGENT) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{job_source} } );


sub get_powershell {
    my (%options) = @_;


    my $job_source = $options{job_source} // VEEAM_JOB_SOURCE_ALL;

    my $ps = '
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

$culture = new-object "System.Globalization.CultureInfo" "en-us"
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
';

    $ps .= centreon::common::powershell::functions::escape_jsonstring(%options);
    $ps .= centreon::common::powershell::functions::convert_to_json(%options);
    $ps .= centreon::common::powershell::veeam::functions::powershell_init();

    $ps .= q~
Try {
    $ErrorActionPreference = "Stop"

    $items = New-Object System.Collections.Generic.List[Hashtable];

    $jobIds = @{}
~;

    if ( $job_source ne VEEAM_JOB_SOURCE_AGENT) {

        $ps .= '
        Get-VBRJob | ForEach-Object {
            $guid = $_.Id.Guid.toString()
            $jobIds[$guid] = $true

            $item = @{}
            $item.name = $_.Name
            $item.type = $_.JobType.value
            $item.isRunning = $_.isRunning
            $item.scheduled = $_.IsScheduleEnabled
            $item.isContinuous = 0

            if ($_.isContinuous -eq $true) {
                $item.isContinuous = 1
            }

            $item.sessions = New-Object System.Collections.Generic.List[Hashtable];
            [Veeam.Backup.Core.CBackupSession]::GetByJob($guid) | Sort-Object CreationTimeUTC -Descending | Select-Object -First 2 | ForEach-Object {
                $session = @{}
                $session.result = $_.Result.value
                $session.creationTimeUTC = (get-date -date $_.CreationTimeUTC.ToUniversalTime() -Uformat ' . "'%s'" . ')
                $session.endTimeUTC = (get-date -date $_.EndTimeUTC.ToUniversalTime() -Uformat ' . "'%s'" . ')
                $item.sessions.Add($session)
            }

            $items.Add($item)
        }
';
    }


    if ( $job_source ne VEEAM_JOB_SOURCE_STANDARD) {
        $ps .= '
        Get-VBRComputerBackupJob | ForEach-Object {
            $id = $_.Id.toString()
            if ($jobIds.ContainsKey($id)) {
                return
            }

            $item = @{}
            $item.name = $_.Name
            $item.mode = $_.Mode.ToString()
            $item.isRunning = $false
            $item.scheduled = $_.ScheduleEnabled
            $item.isContinuous = 0

            if ($_.isContinuous -eq $true) {
                $item.isContinuous = 1
            }

            $item.sessions = New-Object System.Collections.Generic.List[Hashtable];
            try {
                Get-VBRComputerBackupJobSession -name $item.name | Sort-Object CreationTime -Descending | Select-Object -First 2 | ForEach-Object {
                    $session = @{}
                    $session.result = $_.Result.value__ - 1
                    $session.creationTimeUTC = (get-date -date $_.CreationTime.ToUniversalTime() -Uformat ' . "'%s'" . ')
                    $session.endTimeUTC = (get-date -date $_.EndTime.ToUniversalTime() -Uformat ' . "'%s'" . ')
                    $item.sessions.Add($session)
                }
            } catch { }

            $items.Add($item)
        }
';
    }

    $ps .= q~
    $jsonString = $items | ConvertTo-JSON-20 -forceArray $true
    Write-Host $jsonString
} Catch {
    Write-Host $Error[0].Exception
    exit 1
}

exit 0
~;

    return $ps =~ s/^\s+//mr;
}

1;

__END__

=head1 DESCRIPTION

Method to get Veeam job status information.

=cut
