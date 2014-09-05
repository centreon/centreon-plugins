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

package storage::emc::clariion::mode::spinfo;

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
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    my $clariion = $options{custom};
    
    my $response = $clariion->execute_command(cmd => 'getagent -ver -rev -prom -model -type -mem -serial -spid');
    
    my $sp_id = 'unknown';
    my $sp_agent_rev = 'unknown';
    my $sp_flare_rev = 'unknown';
    my $sp_prom_rev = 'unknown';
    my $sp_model = 'unknown';
    my $sp_model_type = 'unknown';
    my $sp_memory_total = 'unknown';
    my $sp_serial_number = 'unknown';

    $sp_id = $1 if ($response =~ /^SP Identifier:\s+(.*)$/im);
    $sp_agent_rev = $1 if ($response =~ /^Agent Rev:\s+(.*)$/im);
    $sp_flare_rev = $1 if ($response =~ /^Revision:\s+(.*)$/im);
    $sp_prom_rev = $1 if ($response =~ /^Prom Rev:\s+(.*)$/im);
    $sp_model = $1 if ($response =~ /^Model:\s+(.*)$/im);
    $sp_model_type = $1 if ($response =~ /^Model Type:\s+(.*)$/im);
    $sp_memory_total = ($1 * 1024 * 1024) if ($response =~ /^SP Memory:\s+(.*)$/im);
    $sp_serial_number = $1 if ($response =~ /^Serial No:\s+(.*)$/im);
    
    my ($memory_value, $memory_unit) = $self->{perfdata}->change_bytes(value => $sp_memory_total);
    
    $self->{output}->output_add(severity => 'ok',
                                short_msg => sprintf('[SP ID: %s] [Agent Revision: %s] [FLARE Revision: %s] [PROM Revision: %s] [Model: %s, %s] [Memory: %s %s] [Serial Number: %s]',
                                                    $sp_id, $sp_agent_rev, $sp_flare_rev, $sp_prom_rev, 
                                                    $sp_model, $sp_model_type, $memory_value, $memory_unit, $sp_serial_number));
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Display informations on the storage processor.

=over 8

=back

=cut
