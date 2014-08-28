################################################################################
# Copyright 2005-2014 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package centreon::common::powershell::exchange::2010::mapimailbox;

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::exchange::2010::powershell;

sub get_powershell {
    my (%options) = @_;
    # options: no_ps
    my $no_ps = (defined($options{no_ps})) ? 1 : 0;
    
    return '' if ($no_ps == 1);
    
    my $ps = centreon::common::powershell::exchange::2010::powershell::powershell_init(%options);
    
    $ps .= '
try { 
    $ErrorActionPreference = "Stop"
    $mapi = test-mapiconnectivity -Identity "' . $options{mailbox} . '"
} catch {
    Write-Host $Error[0].Exception
    exit 1
}

Write-Host "[name=" $mapi.Database "][server=" $mapi.Server "][result=" $mapi.Result "][error=" $mapi.Error "]"

exit 0
';

    return centreon::plugins::misc::powershell_encoded($ps);
}

sub check {
    my ($self, %options) = @_;
    # options: stdout
    
    # Following output:
    #[name= Mailbox Database 0975194476 ][server= SRVI-WIN-TEST ][result= Success ][error=...]
   
    if ($options{stdout} !~ /^\[name=(.*?)\]\[server=(.*?)\]\[result=(.*?)\]\[error=(.*)\]$/) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Cannot find informations');
        return ;
    }
    my ($database, $server, $result, $error) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2), 
                                                centreon::plugins::misc::trim($3), centreon::plugins::misc::trim($4));
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => "MAPI connection to '" . $options{mailbox} . "' is '" . $result . "'.");
    $self->{output}->output_add(long_msg => sprintf("Database: %s, Server: %s\nError: %s",
                                                    $database, $server, $error));
    foreach my $th (('critical_mapi', 'warning_mapi')) {
        next if (!defined($self->{thresholds}->{$th}));
        
        if ($self->{thresholds}->{$th}->{operator} eq '=' && 
            $result =~ /$self->{thresholds}->{$th}->{state}/) {
            $self->{output}->output_add(severity => $self->{thresholds}->{$th}->{out},
                                        short_msg => sprintf("MAPI connection to '%s' is '%s'",
                                                             $options{mailbox}, $result));
        } elsif ($self->{thresholds}->{$th}->{operator} eq '!=' && 
            $result !~ /$self->{thresholds}->{$th}->{state}/) {
            $self->{output}->output_add(severity => $self->{thresholds}->{$th}->{out},
                                        short_msg => sprintf("MAPI connection to '%s' is '%s'",
                                                             $options{mailbox}, $result));
        }
    }
}

1;

__END__

=head1 DESCRIPTION

Method to check Exchange 2010 mapi connection on a specific mailbox.

=cut