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

package hardware::pdu::apc::mode::load;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    1 => ['phaseLoadNormal', 'OK'],
    2 => ['phaseLoadLow', 'WARNING'],
    3 => ['phaseLoadNearOverload', 'WARNING'],
    4 => ['phaseLoadOverload', 'CRITICAL'],
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

    my $oid_rPDULoadStatusLoad = '.1.3.6.1.4.1.318.1.1.12.2.3.1.1.2';
    my $oid_rPDULoadStatusLoadState = '.1.3.6.1.4.1.318.1.1.12.2.3.1.1.3';
    my $oid_rPDULoadStatusPhaseNumber = '.1.3.6.1.4.1.318.1.1.12.2.3.1.1.4';
    my $oid_rPDULoadStatusBankNumber = '.1.3.6.1.4.1.318.1.1.12.2.3.1.1.5';

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_rPDULoadStatusLoad },
                                                            { oid => $oid_rPDULoadStatusLoadState },
                                                            { oid => $oid_rPDULoadStatusPhaseNumber },
                                                            { oid => $oid_rPDULoadStatusBankNumber },
                                                         ],
                                                         , nothing_quit => 1);

    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All phases are ok');

    foreach my $oid (keys %{$self->{results}->{$oid_rPDULoadStatusLoad}}) {    
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;

        my $status_load = $self->{results}->{$oid_rPDULoadStatusLoad}->{$oid} / 10;
        my $status_load_state = $self->{results}->{$oid_rPDULoadStatusLoadState}->{$oid_rPDULoadStatusLoadState . '.' . $instance};
        my $status_phase_number = $self->{results}->{$oid_rPDULoadStatusPhaseNumber}->{$oid_rPDULoadStatusPhaseNumber . '.' . $instance};
        my $status_bank_number = $self->{results}->{$oid_rPDULoadStatusBankNumber}->{$oid_rPDULoadStatusBankNumber . '.' . $instance};

        $self->{output}->output_add(long_msg => sprintf("Phase state on Bank %s is '%s' [Load : %dA]", 
                                            $status_bank_number, ${$states{$status_load_state}}[0], $status_load));
		$self->{output}->perfdata_add(label => 'bank' . $status_bank_number,
                                      value => $status_load,
				      unit => 'A',
                                      min => 0);
		if (${$states{$status_load_state}}[1] ne 'OK') {
             $self->{output}->output_add(severity => ${$states{$status_load_state}}[1],
                                        short_msg => sprintf("Phase state on Bank %s is '%s'", 
                                                             $status_bank_number, ${$states{$status_load_state}}[0],));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check APC phase load.

=over 8

=back

=cut
    
