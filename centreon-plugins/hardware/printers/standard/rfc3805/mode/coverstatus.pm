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

package hardware::printers::standard::rfc3805::mode::coverstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my %cover_status = (
    1 => ["'%s' status is other", 'UNKNOWN'], 
    3 => ["Cover '%s' status is open", 'WARNING'], 
    4 => ["Cover '%s' status is closed", 'OK'], 
    5 => ["Interlock '%s' status is open", 'WARNING'], 
    6 => ["Interlock '%s' status is closed", 'WARNING'], 
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
                                short_msg => "All covers/interlocks are ok.");
    
    my $oid_prtCoverEntry = '.1.3.6.1.2.1.43.6.1.1';
    my $oid_prtCoverDescription = '.1.3.6.1.2.1.43.6.1.1.2';
    my $oid_prtCoverStatus = '.1.3.6.1.2.1.43.6.1.1.3';
    my $result = $self->{snmp}->get_table(oid => $oid_prtCoverEntry, nothing_quit => 1);
    
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_prtCoverStatus\.(.*)/);
        my $index = $1;
        my $status = $result->{$oid_prtCoverStatus . '.' . $index};
        my $descr = centreon::plugins::misc::trim($result->{$oid_prtCoverDescription . '.' . $index});
        
        $self->{output}->output_add(long_msg => sprintf(${$cover_status{$status}}[0], $descr));
        if (!$self->{output}->is_status(value => ${$cover_status{$status}}[1], compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => ${$cover_status{$status}}[1],
                                        short_msg => sprintf(${$cover_status{$status}}[0], $descr));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check covers and interlocks of the printer.

=over 8

=back

=cut
