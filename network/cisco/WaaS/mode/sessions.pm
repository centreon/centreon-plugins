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
# Authors : Simon Bomm <sbomm@merethis.com> & Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package network::cisco::WaaS::mode::sessions;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"       => { name => 'warning', default => '60' },
                                  "critical:s"      => { name => 'critical', default => '70' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{warning} = $self->{option_results}->{warning};
    $self->{critical} = $self->{option_results}->{critical};
    
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning % threshold '" . $self->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical % threshold'" . $self->{critical} . "'.");
       $self->{output}->option_exit();
	}
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
#   Nombre de licences
    my $oid_cwoTfoStatsMaxActiveConn = '.1.3.6.1.4.1.9.9.762.1.2.1.3.0';
#   Nombre de sessions optimized
    my $oid_cwoTfoStatsActiveOptConn = '.1.3.6.1.4.1.9.9.762.1.2.1.2.0';
#   Nombre de session pass-through (non-optimized)
    my $oid_cwoTfoStatsActivePTConn = '.1.3.6.1.4.1.9.9.762.1.2.1.10.0';

    my $result = $self->{snmp}->get_leef(oids => [$oid_cwoTfoStatsMaxActiveConn, $oid_cwoTfoStatsActiveOptConn,
                                                  $oid_cwoTfoStatsActivePTConn], nothing_quit => 1);

    my $prct = $result->{$oid_cwoTfoStatsActiveOptConn} / $result->{$oid_cwoTfoStatsMaxActiveConn} * 100;
    
    my $abs_warning = $self->{perfdata}->get_perfdata_for_output(label => 'warning') / 100 * $result->{$oid_cwoTfoStatsMaxActiveConn};
    my $abs_critical = $self->{perfdata}->get_perfdata_for_output(label => 'critical') / 100 * $result->{$oid_cwoTfoStatsMaxActiveConn};
    
    my $exit = $self->{perfdata}->threshold_check(value => $prct,
                                        threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Passthrough_connections: %d Optimized_connections: %d / %d licences",
                                                     $result->{$oid_cwoTfoStatsActivePTConn}, $result->{$oid_cwoTfoStatsActiveOptConn}, $result->{$oid_cwoTfoStatsMaxActiveConn})
				);

    $self->{output}->perfdata_add(label => "Passthrough_connections", unit => 'con',
                                  value => $result->{$oid_cwoTfoStatsActivePTConn});
    $self->{output}->perfdata_add(label => "Optimized_connections", unit => 'con',
                                  value => $result->{$oid_cwoTfoStatsActiveOptConn},
                                  warning => $abs_warning,
                                  critical => $abs_critical,
                                  min => 0,
				  max => $result->{$oid_cwoTfoStatsMaxActiveConn});
    
    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check optimized and passthrough sessions on Cisco WAAS equipments against total number of licence (CISCO-WAN-OPTIMIZATION-MIB). Available on all Cisco ISR G2 (You need to configure through IOS CLI).

=over 8

=item B<--warning>

Threshold warning: Percentage value of passthrough sessions resulting in a warning state

=item B<--critical-average>

Threshold critical: Percentage value of passthrough sessions resulting in a critical state

=back

==cut
