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

package centreon::common::powershell::windows::liststorages;

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
	';

    if (defined($options{filter})) {
        $ps .= '
    $disks = Get-PSDrive -PSProvider "' . $options{filter} . '"
';
    } else {
        $ps .= '
    $disks = Get-PSDrive
';
    }

    $ps .= '
} Catch {
    Write-Host $Error[0].Exception
	exit 1
}Foreach ($disk in $disks) {
    Write-Host "[name=" $disk.Name "][used=" $disk.Used "][free=" $disk.Free "][provider=" $disk.Provider "][path=" $disk.Root "]" -NoNewline
}

exit 0
';

    return centreon::plugins::misc::powershell_encoded($ps);
}
1;

sub list {
    my ($self, %options) = @_;
    
    # Following output:
    #[name= c ][server= SRVI-WIN-TEST ][used= 20394858038 ][free= 509408308 ][provider= Microsoft.PowerShell.Core\FileSystem ][path= C:\ ]
    #...
    foreach my $line (split /\n/, $options{stdout}) {
	    next if ($line !~ /^\[name=(.*?)\]\[used=(.*?)\]\[free=(.*?)\]\[provider=(.*?)\]\[path=(.*?)\]/);
        my ($disk, $used, $free, $provider, $path) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2), 
                                                      centreon::plugins::misc::trim($3), centreon::plugins::misc::trim($4), centreon::plugins::misc::trim($5));

        $self->{output}->output_add(long_msg => "'" . $disk . "' [used = $used, free = $free, path = $path, provider = " . $provider . ']');

    }
}
1;


sub disco_show {
    my ($self, %options) = @_;
    
    # Following output:
    #[name= c ][server= SRVI-WIN-TEST ][used= 20394858038 ][free= 509408308 ][provider= Microsoft.PowerShell.Core\FileSystem ][path= C:\ ]
    #...
    foreach my $line (split /\n/, $options{stdout}) {
        next if ($line !~ /^\[name=(.*?)\]\[used=(.*?)\]\[free=(.*?)\]\[provider=(.*?)\]\[path=(.*?)\]/);
        my ($disk, $used, $free, $provider, $path) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2), 
                                             centreon::plugins::misc::trim($3), centreon::plugins::misc::trim($4), centreon::plugins::misc::trim($5));

        $self->{output}->add_disco_entry(name     => $disk,
                                         used     => $used,
					 free     => $free,
					 provider => $provider,
                                         path     => $path);
    }
}

1;

__END__

=head1 DESCRIPTION

Method to list Windows Disks.

=cut

