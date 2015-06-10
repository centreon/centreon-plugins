################################################################################
# Copyright 2005-2015 CENTREON
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
# As a special exception, the copyright holders of this program give CENTREON
# permission to link this program with independent modules to produce an executable,
# regardless of the license terms of these independent modules, and to copy and
# distribute the resulting executable under terms of CENTREON choice, provided that
# CENTREON also meet, for each linked independent module, the terms  and conditions
# of the license of that module. An independent module is a module which is not
# derived from this program. If you modify this program, you may extend this
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
#
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package network::hirschmann::common::mode::led;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    1 => ['off', 'UNKNOWN'],
    2 => ['green', 'OK'],
    3 => ['yellow', 'WARNING'],
    4 => ['red', 'CRITICAL'],
);

my $oid_hmLEDRSPowerSupply = '.1.3.6.1.4.1.248.14.1.1.35.1.1.0';
my $oid_hmLEDRStandby = '.1.3.6.1.4.1.248.14.1.1.35.1.2.0';
my $oid_hmLEDRSRedundancyManager = '.1.3.6.1.4.1.248.14.1.1.35.1.3.0';
my $oid_hmLEDRSFault = '.1.3.6.1.4.1.248.14.1.1.35.1.4.0';


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "exclude:s"        => { name => 'exclude' },
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

    $self->{results} = $self->{snmp}->get_leef(oids => [$oid_hmLEDRSPowerSupply, $oid_hmLEDRStandby, $oid_hmLEDRSRedundancyManager, $oid_hmLEDRSFault],
					       nothing_quit => 1);

    $self->{led_psu} = 0;
    $self->{led_standby} = 0;
    $self->{led_redundancy} = 0;
    $self->{led_fault} = 0;

    $self->check_led_psu();
    $self->check_led_standby();
    $self->check_led_redundancy();
    $self->check_led_fault();

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %d leds [PSU led, Standby led, Redundancy led, Fault led] are ok",
                                ($self->{led_psu} + $self->{led_standby} + $self->{led_redundancy} + $self->{led_fault})));

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_led_psu {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking PSU led");
    return if ($self->check_exclude('led_psu'));

    my $led_psu_state = $self->{results}->{ $oid_hmLEDRSPowerSupply };

    $self->{led_psu}++;
    $self->{output}->output_add(long_msg => sprintf("PSU led state is %s.",
                                ${$states{$led_psu_state}}[0]));
    if (${$states{$led_psu_state}}[1] ne 'OK') {
        $self->{output}->output_add(severity =>  ${$states{$led_psu_state}}[1],
                                    short_msg => sprintf("PSU led state is %s.", ${$states{$led_psu_state}}[0]));
    }
}

sub check_led_standby {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking Standby led");
    return if ($self->check_exclude('led_standby'));

    my $led_standby_state = $self->{results}->{ $oid_hmLEDRStandby };

    $self->{led_standby}++;
    $self->{output}->output_add(long_msg => sprintf("Standby led state is %s.",
                                  ${$states{$led_standby_state}}[0]));
    if (${$states{$led_standby_state}}[1] ne 'OK') {
        $self->{output}->output_add(severity =>  ${$states{$led_standby_state}}[1],
                                      short_msg => sprintf("Standby led state is %s.", ${$states{$led_standby_state}}[0]));
    }
}

sub check_led_redundancy {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking Redundancy led");
    return if ($self->check_exclude('led_redundancy'));

    my $led_redundancy_state = $self->{results}->{ $oid_hmLEDRSRedundancyManager };

    $self->{led_redundancy}++;
    $self->{output}->output_add(long_msg => sprintf("Redundancy led state is %s.",
                                  ${$states{$led_redundancy_state}}[0]));
    if (${$states{$led_redundancy_state}}[1] ne 'OK') {
        $self->{output}->output_add(severity =>  ${$states{$led_redundancy_state}}[1],
                                      short_msg => sprintf("Redundancy led state is %s.", ${$states{$led_redundancy_state}}[0]));
    }
}

sub check_led_fault {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking Fault led");
    return if ($self->check_exclude('led_fault'));

    my $led_fault_state = $self->{results}->{ $oid_hmLEDRSFault };

    $self->{led_fault}++;
    $self->{output}->output_add(long_msg => sprintf("Fault led state is %s.",
                                  ${$states{$led_fault_state}}[0]));
    if (${$states{$led_fault_state}}[1] ne 'OK') {
        $self->{output}->output_add(severity =>  ${$states{$led_fault_state}}[1],
                                      short_msg => sprintf("Fault led state is %s.", ${$states{$led_fault_state}}[0]));
    }
}

sub check_exclude {
    my ($self, $section) = @_;

    if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)$section(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping $section section."));
        return 1;
    }
    return 0;
}

1;

__END__

=head1 MODE

Check led  monitor (Power Supplies, Standby, Redundancy, Fault).

=over 8

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=led_fault,led_psu).

=back

=cut

