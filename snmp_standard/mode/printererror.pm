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

package snmp_standard::mode::printererror;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my %errors_printer = (
    0 => ["Printer is low paper", 'WARNING'], 
    1 => ["Printer has no paper", 'WARNING'],
    2 => ["Printer is low toner", 'WARNING'],
    3 => ["Printer has no toner", 'WARNING'], 
    4 => ["Printer has a door open", 'WARNING'], 
    5 => ["Printer is jammed", 'WARNING'], 
    6 => ["Printer is offline", 'WARNING'], 
    7 => ["Printer needs service requested", 'WARNING'], 
    
    8 => ["Printer has input tray missing", 'WARNING'], 
    9 => ["Printer has output tray missing", 'WARNING'], 
    10 => ["Printer has maker supply missing", 'WARNING'], 
    11 => ["Printer output is near full", 'WARNING'], 
    12 => ["Printer output is full", 'WARNING'], 
    13 => ["Printer has input tray empty", 'WARNING'], 
    14 => ["Printer is 'overdue prevent maint'", 'WARNING'], 
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

    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "Printer is ok.");
    
    my $oid_hrPrinterDetectedErrorState = '.1.3.6.1.2.1.25.3.5.1.2';
    my $result = $self->{snmp}->get_table(oid => $oid_hrPrinterDetectedErrorState, nothing_quit => 1);
    
    foreach (keys %$result) {
        my ($value1, $value2) = unpack('C', $result->{$_});
        
        foreach my $key (keys %errors_printer) {
            my ($byte_check, $pos);
            if ($key >= 8) {
                next if (!defined($value2));
                $byte_check = $value2;
                $pos = $key - 8;
            } else {
                $byte_check = $value1;
                $pos = $key
            }
        
            if (($byte_check & (1 << $pos)) &&
                (!$self->{output}->is_status(value => ${$errors_printer{$key}}[1], compare => 'ok', litteral => 1))) {
                $self->{output}->output_add(severity => ${$errors_printer{$key}}[1],
                                            short_msg => sprintf(${$errors_printer{$key}}[0]));
            }
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check printer errors (HOST-RESOURCES-MIB).

=over 8

=back

=cut
