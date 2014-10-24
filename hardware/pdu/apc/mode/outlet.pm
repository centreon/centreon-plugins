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

package hardware::pdu::apc::mode::outlet;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_rPDUOutletStatusOutletName = '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.2';
my $oid_rPDUOutletStatusOutletPhase = '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.3';
my $oid_rPDUOutletStatusOutletState = '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.4';
my $oid_rPDUOutletStatusOutletBank = '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.6';
my $oid_rPDUOutletStatusLoad = '.1.3.6.1.4.1.318.1.1.12.3.5.1.1.7';

my %states = (
    1 => ['outletStatusOn', 'OK'],
    2 => ['outletStatusOff', 'CRITICAL'],
);

my %phases = (
	1 => '1',
    2 => '2',
	3 => '3',
    4 => '1-2',
	5 => '2-3',
    6 => '1-3',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
									"name:s"        => { name => 'name', },
									"regexp"		=> { name => 'use_regexp', },
                                });
    $self->{outlet_selected} = [];
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{result_names} = $self->{snmp}->get_table(oid => $oid_rPDUOutletStatusOutletName, nothing_quit => 1);
 
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{result_names}})) {
	next if ($oid !~ /\.([0-9]+)$/);
	my $instance = $1;
	# Get all without a name
	if (!defined($self->{option_results}->{name})) {
		push @{$self->{outlet_selected}}, $instance; 
		next;
	}
	$self->{result_names}->{$oid} = $self->{output}->to_utf8($self->{result_names}->{$oid});
	if (!defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} eq $self->{option_results}->{name}) {
		push @{$self->{outlet_selected}}, $instance; 
	}
	if (defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} =~ /$self->{option_results}->{name}/) {
		push @{$self->{outlet_selected}}, $instance;
	}
    }
    if (scalar(@{$self->{outlet_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No outlet found for name '" . $self->{option_results}->{name} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    $self->{snmp}->load(oids => [$oid_rPDUOutletStatusOutletPhase,
                                 $oid_rPDUOutletStatusOutletState,
                                 $oid_rPDUOutletStatusOutletBank,
                                 $oid_rPDUOutletStatusLoad],
                        instances => $self->{outlet_selected});
    my $result = $self->{snmp}->get_leef();
    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All outlets are ok.');
    }

    foreach my $instance (@{$self->{outlet_selected}}) {    
        my $outlet_name = $self->{result_names}->{$oid_rPDUOutletStatusOutletName . '.' . $instance};
        my $outlet_phase = $result->{$oid_rPDUOutletStatusOutletPhase . '.' . $instance};
        my $outlet_state = $result->{$oid_rPDUOutletStatusOutletState . '.' . $instance};
        my $outlet_bank = $result->{$oid_rPDUOutletStatusOutletBank . '.' . $instance};
        my $outlet_load = $result->{$oid_rPDUOutletStatusLoad . '.' . $instance} / 10;
		
	$self->{output}->output_add(long_msg => sprintf("Outlet %s '%s' state is '%s' [Bank : %d , Phase : %d] [Load : %dA]", $instance, $outlet_name,
												${$states{$outlet_state}}[0], $outlet_bank, $phases{$outlet_phase}, $outlet_load));
	if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp})) {
		$self->{output}->output_add(severity => ${$states{$outlet_state}}[1],
                                        short_msg => sprintf("Outlet %s '%s' state is '%s' [Bank : %d , Phase : %d]", $instance, $outlet_name,
                                                                 ${$states{$outlet_state}}[0], $outlet_bank, $phases{$outlet_phase}));
	} elsif (${$states{$outlet_state}}[1] ne 'OK') {
		$self->{output}->output_add(severity => ${$states{$outlet_state}}[1],
					short_msg => sprintf("Outlet %s '%s' state is '%s' [Bank : %d , Phase : %d]", $instance, $outlet_name,
								 ${$states{$outlet_state}}[0], $outlet_bank, $phases{$outlet_phase}));
	}
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check APC outlets.

=over 8

=item B<--name>

Set the outlet name.

=item B<--regexp>

Allows to use regexp to filter outlet (with option --name).

=back

=cut
    
