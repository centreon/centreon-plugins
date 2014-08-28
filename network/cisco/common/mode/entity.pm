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

my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';
my $oid_cefcFanTrayOperStatus = '.1.3.6.1.4.1.9.9.117.1.4.1.1.1';
my $oid_cefcPhysicalStatus = '.1.3.6.1.4.1.9.9.117.1.5.1.1.1';
my $oid_cefcFRUPowerOperStatus = '.1.3.6.1.4.1.9.9.117.1.1.2.1.2';
my $oid_cefcModuleOperStatus = '.1.3.6.1.4.1.9.9.117.1.2.1.1.2';

my $thresholds = {
    fan => [
        ['unknown', 'UNKNOWN'],
        ['down', 'CRITICAL'],
        ['warning', 'WARNING'],
        ['up', 'OK'],
    ],
    psu => [
        ['^off*', 'WARNING'],
        ['failed', 'CRITICAL'],
        ['onButFanFail|onButInlinePowerFail', 'WARNING'],
        ['on', 'OK'],
    ],
    module => [
        ['unknown|mdr', 'UNKNOWN'],
        ['disabled|okButDiagFailed|missing|mismatchWithParent|mismatchConfig|dormant|outOfServiceAdmin|outOfServiceEnvTemp|powerCycled|okButPowerOverWarning|okButAuthFailed|fwMismatchFound|fwDownloadFailure', 'WARNING'],
        ['failed|diagFailed|poweredDown|powerDenied|okButPowerOverCritical', 'CRITICAL'],
        ['boot|selfTest|poweredUp|syncInProgress|upgrading|fwDownloadSuccess|ok', 'OK'],
    ],
    physical => [
        ['other', 'UNKNOWN'],
        ['incompatible|unsupported', 'CRITICAL'],
        ['supported', 'OK'],
    ],
};

my %map_states_fan = (
    1 => 'unknown',
    2 => 'up',
    3 => 'down',
    4 => 'warning',
);

my %map_states_psu = (
    1 => 'offEnvOther',
    2 => 'on',
    3 => 'offAdmin',
    4 => 'offDenied',
    5 => 'offEnvPower',
    6 => 'offEnvTemp',
    7 => 'offEnvFan',
    8 => 'failed',
    9 => 'onButFanFail',
    10 => 'offCooling',
    11 => 'offConnectorRating',
    12 => 'onButInlinePowerFail',
);

my %map_states_module = (
    1 => 'unknown'
    2 => 'ok',
    3 => 'disabled',
    4 => 'okButDiagFailed',
    5 => 'boot',
    6 => 'selfTest',
    7 => 'failed',
    8 => 'missing',
    9 => 'mismatchWithParent',
    10 => 'mismatchConfig',
    11 => 'diagFailed',
    12 => 'dormant',
    13 => 'outOfServiceAdmin',
    14 => 'outOfServiceEnvTemp',
    15 => 'poweredDown',
    16 => 'poweredUp',
    17 => 'powerDenied',
    18 => 'powerCycled',
    19 => 'okButPowerOverWarning',
    20 => 'okButPowerOverCritical',
    21 => 'syncInProgress',
    22 => 'upgrading',
    23 => 'okButAuthFailed',
    24 => 'mdr',
    25 => 'fwMismatchFound',
    26 => 'fwDownloadSuccess',
    27 => 'fwDownloadFailure',
);

my %map_states_physical = (
    1 => 'other',
    2 => 'supported',
    3 => 'unsupported',
    4 => 'incompatible',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "exclude:s"        => { name => 'exclude' },
                                  "component:s"      => { name => 'component', default => 'all' },
                                  "no-component:s"          => { name => 'no_component' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });
    
        
    $self->{components} = {};
    $self->{no_components} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ 
                                { oid => $oid_entPhysicalDescr },
                                { oid => $oid_cefcFanTrayOperStatus },
                                { oid => $oid_cefcPhysicalStatus },
                                { oid => $oid_cefcFRUPowerOperStatus },
                                { oid => $oid_cefcModuleOperStatus },
                                               ]);
    
    if ($self->{option_results}->{component} eq 'all') {    
        $self->check_fan();
        $self->check_psu();
        $self->check_physical();
        $self->check_module();
    } elsif ($self->{option_results}->{component} eq 'module') {
        $self->check_module();
    } elsif ($self->{option_results}->{component} eq 'fan') {
        $self->check_fan();
    } elsif ($self->{option_results}->{component} eq 'psu') {
        $self->check_psu();
    } elsif ($self->{option_results}->{component} eq 'physical') {
        $self->check_physical();
    } else {
        $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find component '" . $self->{option_results}->{component} . "'.");
        $self->{output}->option_exit();
    }
    
    my $total_components = 0;
    my $display_by_component = '';
    my $display_by_component_append = '';
    foreach my $comp (sort(keys %{$self->{components}})) {
        # Skipping short msg when no components
        next if ($self->{components}->{$comp}->{total} == 0 && $self->{components}->{$comp}->{skip} == 0);
        $total_components += $self->{components}->{$comp}->{total} + $self->{components}->{$comp}->{skip};
        $display_by_component .= $display_by_component_append . $self->{components}->{$comp}->{total} . '/' . $self->{components}->{$comp}->{skip} . ' ' . $self->{components}->{$comp}->{name};
        $display_by_component_append = ', ';
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %s components [%s] are ok.", 
                                                     $total_components,
                                                     $display_by_component)
                                );

    if (defined($self->{option_results}->{no_component}) && $total_components == 0) {
        $self->{output}->output_add(severity => $self->{no_components},
                                    short_msg => 'No components are checked.');
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($options{instance})) {
        if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{section}}[^,]*#\Q$options{instance}\E#/) {
            $self->{components}->{$options{section}}->{skip}++;
            $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance."));
            return 1;
        }
    } elsif (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)$options{section}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section."));
        return 1;
    }
    return 0;
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

sub check_fan {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fan'));

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cefcFanTrayOperStatus}})) {
        $key =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $fan_descr = $self->{results}->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};
        my $fan_state = $self->{results}->{$oid_cefcFanTrayOperStatus}->{$oid};

        next if ($self->check_exclude(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' state is %s.",
                                    $fan_descr, $map_states_fan{$fan_state}));
        my $exit = $self->get_severity(section => 'fan', value => $map_states_fan{$fan_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' state is %s.", $fan_descr, $map_states_fan{$fan_state}));
        }
    }
}

sub check_psu {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cefcFRUPowerOperStatus}})) {
        $key =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $psu_descr = $self->{results}->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};
        my $psu_state = $self->{results}->{$oid_cefcFRUPowerOperStatus}->{$oid};

        next if ($self->check_exclude(section => 'psu', instance => $instance));
        
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power Supply '%s' state is %s.",
                                    $psu_descr, $map_states_psu{$psu_state}));
        my $exit = $self->get_severity(section => 'psu', value => $map_states_psu{$psu_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power Supply '%s' state is %s.", $psu_descr, $map_states_psu{$psu_state}));
        }
    }
}

sub check_module {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking modules");
    $self->{components}->{module} = {name => 'modules', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'module'));

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cefcModuleOperStatus}})) {
        $key =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $module_descr = $self->{results}->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};
        my $module_state = $self->{results}->{$oid_cefcModuleOperStatus}->{$oid};

        next if ($self->check_exclude(section => 'module', instance => $instance));
        
        $self->{components}->{module}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Module '%s' state is %s.",
                                    $module_descr, $map_states_module{$module_state}));
        my $exit = $self->get_severity(section => 'module', value => $map_states_module{$module_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Module '%s' state is %s.", $module_descr, $map_states_module{$module_state}));
        }
    }
}

sub check_physical {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking physicals");
    $self->{components}->{physical} = {name => 'physical', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'physical'));

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cefcPhysicalStatus}})) {
        $key =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $physical_descr = $self->{results}->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};
        my $physical_state = $self->{results}->{$oid_cefcPhysicalStatus}->{$oid};

        next if ($self->check_exclude(section => 'physical', instance => $instance));
        
        $self->{components}->{physical}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Physical '%s' state is %s.",
                                    $physical_descr, $map_states_physical{$physical_state}));
        my $exit = $self->get_severity(section => 'physical', value => $map_states_physical{$physical_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Physical '%s' state is %s.", $physical_descr, $map_states_physical{$physical_state}));
        }
    }
}

1;

__END__

=head1 MODE

Check Environment monitor (CISCO-ENTITY-SENSOR-MIB) (Fans, Power Supplies, Modules, Physical Entities).

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'module', 'physical', 'fan', 'psu'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=psu)
Can also exclude specific instance: --exclude='psu#1#'

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,CRITICAL,^(?!(on)$)'

=back

=cut
    
