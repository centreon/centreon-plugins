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

package centreon::common::powershell::exchange::mailboxes;

use strict;
use warnings;
use centreon::common::powershell::exchange::powershell;
use centreon::common::powershell::functions;

sub get_powershell {
    my (%options) = @_;

    my $ps = centreon::common::powershell::exchange::powershell::powershell_init(%options);
    $ps .= centreon::common::powershell::functions::escape_jsonstring(%options);
    $ps .= centreon::common::powershell::functions::convert_to_json(%options);

    my $extra_matches = '';
    if (defined($options{ps_match_server}) && $options{ps_match_server} ne '') {
        $extra_matches .= ' | ?{$_.ServerName -match "' . $options{ps_match_server} . '"}';
    }
    if (defined($options{ps_match_database}) && $options{ps_match_database} ne '') {
        $extra_matches .= ' | ?{$_.Database -match "' . $options{ps_match_database} . '"}';
    }

    $ps .= '
try {
    $ErrorActionPreference = "Stop"
';
    if (defined($options{ps_database}) && $options{ps_database} ne '') {
        $ps .= '
    $mailboxes = Get-Mailbox -ResultSize unlimited -WarningAction SilentlyContinue -Database "' . $options{ps_database} . '"
    $folder_mailboxes = Get-Mailbox -PublicFolder:$true -ResultSize unlimited -WarningAction SilentlyContinue -Database "' . $options{ps_database} . '" ' . $extra_matches .'
';
    } elsif (defined($options{ps_server}) && $options{ps_server} ne '') {
        $ps .= '
    $mailboxes = Get-Mailbox -ResultSize unlimited -WarningAction SilentlyContinue -Server "' . $options{ps_server} . '"
    $folder_mailboxes = Get-Mailbox -PublicFolder:$true -ResultSize unlimited -WarningAction SilentlyContinue -Server "' . $options{ps_server} . '" ' . $extra_matches .'
';
    } else {
        $ps .= '
    $mailboxes = Get-Mailbox -ResultSize unlimited -WarningAction SilentlyContinue ' . $extra_matches . '
    $folder_mailboxes = Get-Mailbox -PublicFolder:$true -ResultSize unlimited -WarningAction SilentlyContinue ' . $extra_matches . '
';
    }

    $ps .= '
    $result = @{}
    $result.users = @{
        total = 0;
        over_quota = 0;
        warning_quota = 0;
        unlimited = 0;
        over_quota_details = New-Object System.Collections.Generic.List[Hashtable];
        warning_quota_details = New-Object System.Collections.Generic.List[Hashtable];
        unlimited_details = New-Object System.Collections.Generic.List[Hashtable]
    }
    $result.public_folders = @{
        total = 0;
        over_quota = 0;
        warning_quota = 0;
        unlimited = 0;
        over_quota_details = New-Object System.Collections.Generic.List[Hashtable];
        warning_quota_details = New-Object System.Collections.Generic.List[Hashtable];
        unlimited_details = New-Object System.Collections.Generic.List[Hashtable]
    }
    $result.group_by_databases = @{}
    foreach ($mailbox in $mailboxes) {
        $item = @{}

        $detail = @{
            database = $mailbox.Database.Name;
            server_name = $mailbox.ServerName;
            name = $mailbox.Name
        }
        if (-not $result.group_by_databases[$mailbox.Database]) {
            $result.group_by_databases[$mailbox.Database] = 0
        }
        $result.group_by_databases[$mailbox.Database]++
        $result.users.total++
        if (($null -eq $mailbox.ProhibitSendReceiveQuota -or $mailbox.ProhibitSendReceiveQuota.IsUnlimited -eq $true) -or ($null -eq $mailbox.ProhibitSendQuota -or $mailbox.ProhibitSendQuota.IsUnlimited -eq $true)) {
            $result.users.unlimited++
            $result.users.unlimited_details.Add($detail)
        }

        if ($mailbox.ProhibitSendReceiveQuota -ne "unlimited" -or $mailbox.ProhibitSendQuota -ne "unlimited") {
            $stat = get-mailboxStatistics -Identity $mailbox.Identity -ErrorAction SilentlyContinue
            if ($stat) {
                $size_bytes = $stat.TotalItemSize.Value.ToBytes()
                if ($null -ne $mailbox.ProhibitSendQuota -and $mailbox.ProhibitSendQuota.IsUnlimited -eq $false -and $size_bytes > $mailbox.ProhibitSendQuota.Value.ToBytes()) {
                    $result.users.over_quota++
                    $result.users.over_quota_details.Add($detail)
                } elseif ($null -ne $mailbox.ProhibitSendReceiveQuota -and $mailbox.ProhibitSendReceiveQuota.IsUnlimited -eq $false -and $size_bytes > $mailbox.ProhibitSendReceiveQuota.Value.ToBytes()) {
                    $result.users.over_quota++
                    $result.users.over_quota_details.Add($detail)
                } elseif ($null -ne $mailbox.issueWarningQuota -and $mailbox.issueWarningQuota.IsUnlimited -eq $false -and $size_bytes > $mailbox.issueWarningQuota.Value.ToBytes()) {
                    $result.users.warning_quota++
                    $result.users.warning_quota_details.Add($detail)
                }
            }
        }
    }

    foreach ($mailbox in $folder_mailboxes) {
        $item = @{}

        $detail = @{
            database = $mailbox.Database.Name;
            server_name = $mailbox.ServerName;
            name = $mailbox.Name
        }
        $result.public_folders.total++
        if (($null -eq $mailbox.ProhibitSendReceiveQuota -or $mailbox.ProhibitSendReceiveQuota.IsUnlimited -eq $true) -or ($null -eq $mailbox.ProhibitSendQuota -or $mailbox.ProhibitSendQuota.IsUnlimited -eq $true)) {
            $result.public_folders.unlimited++
            $result.public_folders.unlimited_details.Add($detail)
        }

        if ($mailbox.ProhibitSendReceiveQuota -ne "unlimited" -or $mailbox.ProhibitSendQuota -ne "unlimited") {
            $stat = get-mailboxStatistics -Identity $mailbox.Identity -ErrorAction SilentlyContinue
            if ($stat) {
                $size_bytes = $stat.TotalItemSize.Value.ToBytes()
                if ($null -ne $mailbox.ProhibitSendQuota -and $mailbox.ProhibitSendQuota.IsUnlimited -eq $false -and $size_bytes > $mailbox.ProhibitSendQuota.Value.ToBytes()) {
                    $result.public_folders.over_quota++
                    $result.public_folders.over_quota_details.Add($detail)
                } elseif ($null -ne $mailbox.ProhibitSendReceiveQuota -and $mailbox.ProhibitSendReceiveQuota.IsUnlimited -eq $false -and $size_bytes > $mailbox.ProhibitSendReceiveQuota.Value.ToBytes()) {
                    $result.public_folders.over_quota++
                    $result.public_folders.over_quota_details.Add($detail)
                } elseif ($null -ne $mailbox.issueWarningQuota -and $mailbox.issueWarningQuota.IsUnlimited -eq $false -and $size_bytes > $mailbox.issueWarningQuota.Value.ToBytes()) {
                    $result.public_folders.warning_quota++
                    $result.public_folders.warning_quota_details.Add($detail)
                }
            }
        }
    }

    $jsonString = $result | ConvertTo-JSON-20
    Write-Host $jsonString
    exit 0
} catch {
    Write-Host $Error[0].Exception
    exit 1
}
';

    return $ps;
}

1;

__END__

=head1 DESCRIPTION

Method to check Exchange mailboxes.

=cut
