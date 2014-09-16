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

package hardware::ups::mge::mode::outputsource;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_upsmgOutput = '.1.3.6.1.4.1.705.1.7';
my $oid_upsmgOutputOnBatteryEntry = '.1.3.6.1.4.1.705.1.7.3';

my %map_output_status = (
    '.1.3.6.1.4.1.705.1.7.3.0' => 'OutputOnBattery', 
    '.1.3.6.1.4.1.705.1.7.4.0' => 'OutputOnByPass', 
    '.1.3.6.1.4.1.705.1.7.5.0' => 'OutputUnavailableByPass',
    '.1.3.6.1.4.1.705.1.7.6.0' => 'OutputNoByPass',
    '.1.3.6.1.4.1.705.1.7.7.0' => 'OutputUtilityOff',
    '.1.3.6.1.4.1.705.1.7.8.0' => 'OutputOnBoost',
    '.1.3.6.1.4.1.705.1.7.9.0' => 'OutputInverterOff',
    '.1.3.6.1.4.1.705.1.7.10.0' => 'OutputOverLoad',
    '.1.3.6.1.4.1.705.1.7.11.0' => 'OutputOverTemp',
    '.1.3.6.1.4.1.705.1.7.12.0' => 'OutputOnBuck',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-status:s" => { name => 'filter_status', default => '^OutputInverterOff'},
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
    
    my $result = $self->{snmp}->get_table(oid => $oid_upsmgOutput, start => $oid_upsmgOutputOnBatteryEntry, nothing_quit => 1);
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Output status is ok"));
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %map_output_status)) {
        next if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' && $map_output_status{$oid} =~ /$self->{option_results}->{filter_status}/);
        if (defined($result->{$oid}) && $result->{$oid} == 1) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Output status is '%s'", $map_output_status{$oid}));
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check output source status.

=over 8

=item B<--filter-status>

Filter on status. (can be a regexp)
Default: ^OutputInverterOff

=back

=cut
