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

package network::cisco::common::mode::entity;

use base qw(centreon::plugins::mode);

use strict;
use warnings;


my %map_states_fan = (
    1 => ['unknown', 'WARNING'],
    2 => ['up', 'OK'],
    3 => ['down', 'CRITICAL'],
    4 => ['warning', 'WARNING']
);

my %map_states_psu = (
    1 => ['offEnvOther', 'WARNING'],
    2 => ['on', 'OK'],
    3 => ['offAdmin', 'WARNING'],
    4 => ['offDenied', 'WARNING'],
    5 => ['offEnvPower', 'WARNING'],
    6 => ['offEnvTemp', 'WARNING'],
    7 => ['offEnvFan', 'WARNING'],
    8 => ['failed', 'CRITICAL'],
    9 => ['onButFanFail', 'WARNING'],
    10 => ['offCooling', 'WARNING'],
    11 => ['offConnectorRating', 'WARNING'],
    12 => ['onButInlinePowerFail', 'WARNING'],
);

my %map_states_mod = (
    1 => ['unknown', 'WARNING'],
    2 => ['ok', 'OK'],
    3 => ['disabled', 'WARNING'],
    4 => ['okButDiagFailed', 'WARNING'],
    5 => ['boot', 'WARNING'],
    6 => ['selfTest', 'WARNING'],
    7 => ['failed', 'CRITICAL'],
    8 => ['missing', 'CRITICAL'],
    9 => ['mismatchWithParent', 'WARNING'],
    10 => ['mismatchConfig', 'WARNING'],
    11 => ['diagFailed', 'CRITICAL'],
    12 => ['dormant', 'WARNING'],
    13 => ['outOfServiceAdmin', 'WARNING'],
    14 => ['outOfServiceEnvTemp', 'WARNING'],
    15 => ['poweredDown', 'CRITICAL'],
    16 => ['poweredUp', 'OK'],
    17 => ['powerDenied', 'CRITICAL'],
    18 => ['powerCycled', 'WARNING'],
    19 => ['okButPowerOverWarning', 'WARNING'],
    20 => ['okButPowerOverCritical', 'CRITICAL'],
    21 => ['syncInProgress', 'WARNING'],
    22 => ['upgrading', 'WARNING'],
    23 => ['okButAuthFailed', 'WARNING'],
    24 => ['mdr', 'WARNING'],
    25 => ['fwMismatchFound', 'WARNING'],
    26 => ['fwDownloadSuccess', 'OK'],
    27 => ['fwDownloadFailure', 'WARNING'],
);

my %map_states_phy = (
    1 => ['other', 'WARNING'],
    2 => ['supported', 'OK'],
    3 => ['unsupported', 'CRITICAL'],
    4 => ['incompatible', 'CRITICAL'],
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
    $self->{components_mods} = 0;
    $self->{components_phys} = 0;
    
    $self->check_fans();
    $self->check_psus();
    $self->check_mods();
    $self->check_phys();
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %d components [%d fans, %d power supplies, %d modules, %d physical entities] are ok.", 
                                ($self->{components_fans} + $self->{components_psus} + $self->{components_mods}, $self->{components_phys}), 
                                $self->{components_fans}, $self->{components_psus}, $self->{components_mods}, $self->{components_phys}));
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub check_fans {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    return if ($self->check_exclude('fan'));
    
    my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';
    my $oid_cefcFanTrayOperStatus = '.1.3.6.1.4.1.9.9.117.1.4.1.1.1';

    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_entPhysicalDescr
                                                            },
                                                            { oid => $oid_cefcFanTrayOperStatus
                                                            }],
                                                         nothing_quit => 1);

    foreach my $oid (keys %{$results->{$oid_cefcFanTrayOperStatus}}) {
        return if (scalar(keys %$results) <= 0);
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $fan_descr = $results->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};
        my $fan_state = $results->{$oid_cefcFanTrayOperStatus}->{$oid};

        $self->{components_fans}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' state is %s.",
                                    $fan_descr, ${$map_states_fan{$fan_state}}[0]));
        if (${$map_states_fan{$fan_state}}[1] ne 'OK') {
            $self->{output}->output_add(severity =>  ${$map_states_fan{$fan_state}}[1],
            short_msg => sprintf("Fan '%s' state is %s.", $fan_descr, ${$map_states_fan{$fan_state}}[0]));
        }
    }
}

sub check_psus {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    return if ($self->check_exclude('psu'));

    my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';
    my $oid_cefcFRUPowerOperStatus = '.1.3.6.1.4.1.9.9.117.1.1.2.1.2';

    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_entPhysicalDescr
                                                            },
                                                            { oid => $oid_cefcFRUPowerOperStatus
                                                            }],
                                                         nothing_quit => 1);

    foreach my $oid (keys %{$results->{$oid_cefcFRUPowerOperStatus}}) {
        return if (scalar(keys %$results) <= 0);
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $psu_descr = $results->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};
        my $psu_state = $results->{$oid_cefcFRUPowerOperStatus}->{$oid};

        $self->{components_psus}++;
        $self->{output}->output_add(long_msg => sprintf("Power Supply '%s' state is %s.",
                                    $psu_descr, ${$map_states_psu{$psu_state}}[0]));
        if (${$map_states_psu{$psu_state}}[1] ne 'OK') {
            $self->{output}->output_add(severity =>  ${$map_states_psu{$psu_state}}[1],
            short_msg => sprintf("Power Supply '%s' state is %s.", $psu_descr, ${$map_states_psu{$psu_state}}[0]));
        }
    }
}

sub check_mods {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking modules");
    return if ($self->check_exclude('mod'));

    my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';
    my $oid_cefcModuleOperStatus = '.1.3.6.1.4.1.9.9.117.1.2.1.1.2';

    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_entPhysicalDescr
                                                            },
                                                            { oid => $oid_cefcModuleOperStatus
                                                            }],
                                                         nothing_quit => 1);

    foreach my $oid (keys %{$results->{$oid_cefcModuleOperStatus}}) {
        return if (scalar(keys %$results) <= 0);
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $mod_descr = $results->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};
        my $mod_state = $results->{$oid_cefcModuleOperStatus}->{$oid};

        $self->{components_mods}++;
        $self->{output}->output_add(long_msg => sprintf("Module '%s' state is %s.",
                                    $mod_descr, ${$map_states_mod{$mod_state}}[0]));
        if (${$map_states_mod{$mod_state}}[1] ne 'OK') {
            $self->{output}->output_add(severity =>  ${$map_states_mod{$mod_state}}[1],
            short_msg => sprintf("Power Supply '%s' state is %s.", $mod_descr, ${$map_states_mod{$mod_state}}[0]));
        }
    }
}

sub check_phys {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking modules");
    return if ($self->check_exclude('phy'));

    my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';
    my $oid_cefcPhysicalStatus = '.1.3.6.1.4.1.9.9.117.1.5.1.1.1';

    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_entPhysicalDescr
                                                            },
                                                            { oid => $oid_cefcPhysicalStatus
                                                            }],
                                                         nothing_quit => 1);

    foreach my $oid (keys %{$results->{$oid_cefcPhysicalStatus}}) {
        return if (scalar(keys %$results) <= 0);
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $phy_descr = $results->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};
        my $phy_state = $results->{$oid_cefcPhysicalStatus}->{$oid};

        $self->{components_phys}++;
        $self->{output}->output_add(long_msg => sprintf("Physical entity '%s' state is %s.",
                                    $phy_descr, ${$map_states_phy{$phy_state}}[0]));
        if (${$map_states_phy{$phy_state}}[1] ne 'OK') {
            $self->{output}->output_add(severity =>  ${$map_states_phy{$phy_state}}[1],
            short_msg => sprintf("Power Supply '%s' state is %s.", $phy_descr, ${$map_states_phy{$phy_state}}[0]));
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

Check Environment monitor (CISCO-ENTITY-SENSOR-MIB) (Fans, Power Supplies, Modules, Physical Entities).

=over 8

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=fan,psu,mod,phy).

=back

=cut
    
