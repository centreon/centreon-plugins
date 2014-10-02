################################################################################
# Copyright 2005-2013 MERETHIS
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

package centreon::common::fortinet::fortigate::mode::clusterstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_fgHaSystemMode = '.1.3.6.1.4.1.12356.101.13.1.1'; # '.0' to have the mode
my $oid_fgHaStatsSerial = '.1.3.6.1.4.1.12356.101.13.2.1.1.2';
my $oid_fgHaStatsMasterSerial = '.1.3.6.1.4.1.12356.101.13.2.1.1.16';
my $oid_fgHaStatsSyncStatus = '.1.3.6.1.4.1.12356.101.13.2.1.1.12';

my %maps_ha_mode = (
    1 => 'standalone',
    2 => 'activeActive',
    3 => 'activePassive',
);

my %maps_sync_status = (
    0 => 'not synchronized',
    1 => 'synchronized',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}
    
sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    $self->{result} = $self->{snmp}->get_multiple_table(oids => [
                                                                  { oid => $oid_fgHaSystemMode },
                                                                  { oid => $oid_fgHaStatsMasterSerial },
                                                                  { oid => $oid_fgHaStatsSerial },
                                                                  { oid => $oid_fgHaStatsSyncStatus },
                                                                ], 
                                                        nothing_quit => 1);
    
    # Check if mode cluster
    my $ha_mode = $self->{result}->{$oid_fgHaSystemMode}->{$oid_fgHaSystemMode . '.0'};
    my $ha_output = defined($maps_ha_mode{$ha_mode}) ? $maps_ha_mode{$ha_mode} : 'unknown';
    $self->{output}->output_add(long_msg => 'High availabily mode is ' . $ha_output . '.');
    if ($ha_mode == 1) {
        $self->{output}->output_add(severity => 'ok',
                                    short_msg => sprintf("No cluster configuration (standalone mode)."));
    } else {
        $self->{output}->output_add(severity => 'ok',
                                    short_msg => sprintf("Cluster status is ok."));
        
        foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{result}->{$oid_fgHaStatsSerial}})) {
            next if ($key !~ /^$oid_fgHaStatsSerial\.([0-9]+)$/);

            if ($ha_mode == 3) {
                my $state = $self->{result}->{$oid_fgHaStatsMasterSerial}->{$oid_fgHaStatsMasterSerial . '.' . $1} eq '' ? 
                            'master' : 'slave';
                $self->{output}->output_add(long_msg => sprintf("Node '%s' is %s.", 
                                                    $self->{result}->{$oid_fgHaStatsSerial}->{$key}, $state));
            }
            
            my $sync_status = $self->{result}->{$oid_fgHaStatsSyncStatus}->{$oid_fgHaStatsSyncStatus . '.' . $1};
            next if (!defined($sync_status));
            
            $self->{output}->output_add(long_msg => sprintf("Node '%s' sync-status is %s.", 
                                                    $self->{result}->{$oid_fgHaStatsSerial}->{$key}, $maps_sync_status{$sync_status}));
            if ($sync_status == 0) {
                $self->{output}->output_add(severity => 'critical',
                                    short_msg => sprintf("Node '%s' sync-status is %s.", 
                                                    $self->{result}->{$oid_fgHaStatsSerial}->{$key}, $maps_sync_status{$sync_status}));
            }
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check cluster status (FORTINET-FORTIGATE-MIB).

=over 8

=back

=cut