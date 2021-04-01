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

package centreon::common::powershell::exchange::listdatabases;

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::exchange::powershell;

sub get_powershell {
    my (%options) = @_;
    
    my $ps = centreon::common::powershell::exchange::powershell::powershell_init(%options);
    
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
Foreach ($DB in $MountedDB) {
    Write-Host "[name=" $DB.Name "][server=" $DB.Server "][mounted=" $DB.Mounted "][size=" $DB.DatabaseSize "][asize=" $DB.AvailableNewMailboxSpace "]" -NoNewline
    
';
    $ps .= '
}

exit 0
';

    return $ps;
}

sub list {
    my ($self, %options) = @_;
    
    # Following output:
    #[name= Mailbox Database 0975194476 ][server= SRVI-WIN-TEST ][mounted= True ][size= 136.1 MB (142,671,872 bytes) ][asize= 124.4 MB (130,482,176 bytes) ][mapi= Success ][mailflow= Success ][latency= 50,00 ]
    #...
    
    foreach my $line (split /\n/, $options{stdout}) {
        next if ($line !~ /^\[name=(.*?)\]\[server=(.*?)\]\[mounted=(.*?)\]\[size=(.*?)\]\[asize=(.*?)\]/);
        my ($database, $server, $mounted, $size, $asize) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2), 
                                             centreon::plugins::misc::trim($3), centreon::plugins::misc::trim($4), centreon::plugins::misc::trim($5));

        $self->{output}->output_add(long_msg => "'" . $database . "' [server = $server, mounted = " . $mounted .  ']');
    }
}

sub disco_show {
    my ($self, %options) = @_;
    
    # Following output:
    #[name= Mailbox Database 0975194476 ][server= SRVI-WIN-TEST ][mounted= True ][size= 136.1 MB (142,671,872 bytes) ][asize= 124.4 MB (130,482,176 bytes) ][mapi= Success ][mailflow= Success ][latency= 50,00 ]
    #...
    
    foreach my $line (split /\n/, $options{stdout}) {
        next if ($line !~ /^\[name=(.*?)\]\[server=(.*?)\]\[mounted=(.*?)\]\[size=(.*?)\]\[asize=(.*?)\]/);
        my ($database, $server, $mounted, $size, $asize) = (
            centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2), 
            centreon::plugins::misc::trim($3), centreon::plugins::misc::trim($4), centreon::plugins::misc::trim($5)
        );

        $self->{output}->add_disco_entry(
            name => $database,
            server => $server,
            mounted => $mounted
        );
    }
}

1;

__END__

=head1 DESCRIPTION

Method to list Exchange databases.

=cut
