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

package network::hirschmann::common::mode::environment;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    1 => ['normal', 'OK'],
    2 => ['warning', 'WARNING'],
    3 => ['critical', 'CRITICAL'],
    4 => ['shutdown', 'CRITICAL'],
    5 => ['not present', 'OK'],
    6 => ['not functioning', 'WARNING'],
);
my %map_psu_source = (
    1 => 'unknown',
    2 => 'ac',
    3 => 'dc',
    4 => 'externalPowerSupply',
    5 => 'internalRedundant'
);

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

    $self->{components_fans} = 0;
    $self->{components_psus} = 0;

    $self->get_type();
    $self->check_fans();
    $self->check_psus();

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %d components [%d fans, %d power supplies] are ok",
                                ($self->{components_fans} + $self->{components_psus}),
                                $self->{components_fans}, $self->{components_psus}));

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_fans {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    return if ($self->check_exclude('fans'));

    my $oid_ciscoEnvMonFanStatusEntry = '.1.3.6.1.4.1.9.9.13.1.4.1';
    my $oid_ciscoEnvMonFanStatusDescr = '.1.3.6.1.4.1.9.9.13.1.4.1.2';
    my $oid_ciscoEnvMonFanState = '.1.3.6.1.4.1.9.9.13.1.4.1.3';

    my $result = $self->{snmp}->get_table(oid => $oid_ciscoEnvMonFanStatusEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $oid (keys %$result) {
        next if ($oid !~ /^$oid_ciscoEnvMonFanStatusDescr/);
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;

        my $fan_descr = $result->{$oid};
        my $fan_state = $result->{$oid_ciscoEnvMonFanState . '.' . $instance};

        $self->{components_fans}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' state is %s.",
                                    $fan_descr, ${$states{$fan_state}}[0]));
        if (${$states{$fan_state}}[1] ne 'OK') {
            $self->{output}->output_add(severity =>  ${$states{$fan_state}}[1],
                                        short_msg => sprintf("Fan '%s' state is %s.", $fan_descr, ${$states{$fan_state}}[0]));
        }
    }
}

sub check_psus {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    return if ($self->check_exclude('psu'));

    my $oid_ciscoEnvMonSupplyStatusEntry = '.1.3.6.1.4.1.9.9.13.1.5.1';
    my $oid_ciscoEnvMonSupplyStatusDescr = '.1.3.6.1.4.1.9.9.13.1.5.1.2';
    my $oid_ciscoEnvMonSupplyState = '.1.3.6.1.4.1.9.9.13.1.5.1.3';
    my $oid_ciscoEnvMonSupplySource = '.1.3.6.1.4.1.9.9.13.1.5.1.4';

    my $result = $self->{snmp}->get_table(oid => $oid_ciscoEnvMonSupplyStatusEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $oid (keys %$result) {
        next if ($oid !~ /^$oid_ciscoEnvMonSupplyStatusDescr/);
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;

        my $psu_descr = $result->{$oid};
        my $psu_state = $result->{$oid_ciscoEnvMonSupplyState . '.' . $instance};
        my $psu_source = $result->{$oid_ciscoEnvMonSupplySource . '.' . $instance};

        $self->{components_psus}++;
        $self->{output}->output_add(long_msg => sprintf("Power Supply '%s' [type: %s] state is %s.",
                                    $psu_descr, $map_psu_source{$psu_source}, ${$states{$psu_state}}[0]));
        if (${$states{$psu_state}}[1] ne 'OK') {
            $self->{output}->output_add(severity =>  ${$states{$psu_state}}[1],
                                        short_msg => sprintf("Power Supply '%s' state is %s.", $psu_descr, ${$states{$psu_state}}[0]));
        }
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

Check Environment monitor (Fans, Power Supplies).

=over 8

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=psu).

=back

=cut

