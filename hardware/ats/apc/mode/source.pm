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

package hardware::ats::apc::mode::source;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %selected_source = (
    1 => 'sourceA',
    2 => 'sourceB',
);

my %redundancy_states = (
    1 => ['atsRedundancyLost', 'CRITICAL'],
    2 => ['atsFullyRedundant', 'OK'],
);

my %sourceA_states = (
    1 => ['fail', 'CRITICAL'],
    2 => ['ok', 'OK'],
);

my %sourceB_states = (
    1 => ['fail', 'CRITICAL'],
    2 => ['ok', 'OK'],
);

my %phaseSync_states = (
    1 => ['inSync', 'OK'],
    2 => ['outOfSync', 'CRITICAL'],
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

    my $oid_atsStatusSelectedSource = '.1.3.6.1.4.1.318.1.1.8.5.1.2.0';
    my $oid_atsStatusRedundancyStatus = '.1.3.6.1.4.1.318.1.1.8.5.1.3.0';
    my $oid_atsStatusSourceAStatus = '.1.3.6.1.4.1.318.1.1.8.5.1.12.0';
    my $oid_atsStatusSourceBStatus = '.1.3.6.1.4.1.318.1.1.8.5.1.13.0';
    my $oid_atsStatusPhaseSyncStatus = '.1.3.6.1.4.1.318.1.1.8.5.1.14.0';

    $self->{results} = $self->{snmp}->get_leef(oids => [$oid_atsStatusSelectedSource, $oid_atsStatusSelectedSource, $oid_atsStatusRedundancyStatus, $oid_atsStatusSourceAStatus, $oid_atsStatusSourceBStatus, $oid_atsStatusPhaseSyncStatus], nothing_quit => 1);

    my $exit1 = ${$redundancy_states{$self->{results}->{$oid_atsStatusRedundancyStatus}}}[1];
    my $exit2 = ${$sourceA_states{$self->{results}->{$oid_atsStatusSourceAStatus}}}[1];
    my $exit3 = ${$sourceB_states{$self->{results}->{$oid_atsStatusSourceBStatus}}}[1];
    my $exit4 = ${$phaseSync_states{$self->{results}->{$oid_atsStatusPhaseSyncStatus}}}[1];

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All sources are ok');

    $self->{output}->output_add(long_msg => sprintf("Selected source is '%s'", $selected_source{$self->{results}->{$oid_atsStatusSelectedSource}}));
    $self->{output}->output_add(long_msg => sprintf("Redundancy state is '%s'", ${$redundancy_states{$self->{results}->{$oid_atsStatusRedundancyStatus}}}[0]));
    $self->{output}->output_add(long_msg => sprintf("Source A state is '%s'", ${$sourceA_states{$self->{results}->{$oid_atsStatusSourceAStatus}}}[0]));
    $self->{output}->output_add(long_msg => sprintf("Source B state is '%s'", ${$sourceB_states{$self->{results}->{$oid_atsStatusSourceBStatus}}}[0]));
    $self->{output}->output_add(long_msg => sprintf("Phase sync is '%s'", ${$phaseSync_states{$self->{results}->{$oid_atsStatusPhaseSyncStatus}}}[0]));
    
    if (!$self->{output}->is_status(value => $exit1, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit1,
                                short_msg => sprintf("Redundancy state is '%s'", ${$redundancy_states{$self->{results}->{$oid_atsStatusRedundancyStatus}}}[0]));
    }
    if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit2,
                                short_msg => sprintf("Source A state is '%s'", ${$sourceA_states{$self->{results}->{$oid_atsStatusSourceAStatus}}}[0]));
    }
    if (!$self->{output}->is_status(value => $exit3, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit3,
                                short_msg => sprintf("Source B state is '%s'", ${$sourceB_states{$self->{results}->{$oid_atsStatusSourceBStatus}}}[0]));
    }
    if (!$self->{output}->is_status(value => $exit4, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit4,
                                short_msg => sprintf("Phase sync is '%s'", ${$phaseSync_states{$self->{results}->{$oid_atsStatusPhaseSyncStatus}}}[0]));
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check APC ATS sources.

=over 8

=back

=cut
    
