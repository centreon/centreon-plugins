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

package hardware::server::hp::proliant::snmp::mode::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use hardware::server::hp::proliant::snmp::mode::components::cpu;
use hardware::server::hp::proliant::snmp::mode::components::psu;
use hardware::server::hp::proliant::snmp::mode::components::pc;
use hardware::server::hp::proliant::snmp::mode::components::fan;
use hardware::server::hp::proliant::snmp::mode::components::temperature;
use hardware::server::hp::proliant::snmp::mode::components::network;
use hardware::server::hp::proliant::snmp::mode::components::ida;
use hardware::server::hp::proliant::snmp::mode::components::fca;
use hardware::server::hp::proliant::snmp::mode::components::ide;
use hardware::server::hp::proliant::snmp::mode::components::sas;
use hardware::server::hp::proliant::snmp::mode::components::scsi;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "exclude:s"        => { name => 'exclude' },
                                  "absent-problem:s" => { name => 'absent' },
                                  "component:s"      => { name => 'component', default => 'all' },
                                  "no-component:s"   => { name => 'no_component' },
                                });

    $self->{product_name} = undef;
    $self->{serial} = undef;
    $self->{romversion} = undef;
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
}

sub global {
    my ($self, %options) = @_;
 
    $self->get_system_information();
    hardware::server::hp::proliant::snmp::mode::components::cpu::check($self);
    hardware::server::hp::proliant::snmp::mode::components::psu::check($self);
    hardware::server::hp::proliant::snmp::mode::components::pc::check($self);
    hardware::server::hp::proliant::snmp::mode::components::fan::check($self);
    hardware::server::hp::proliant::snmp::mode::components::temperature::check($self);
    hardware::server::hp::proliant::snmp::mode::components::network::physical_nic($self);
    hardware::server::hp::proliant::snmp::mode::components::network::logical_nic($self);
    hardware::server::hp::proliant::snmp::mode::components::ida::array_controller($self);
    hardware::server::hp::proliant::snmp::mode::components::ida::array_accelerator($self);
    hardware::server::hp::proliant::snmp::mode::components::ida::logical_drive($self);
    hardware::server::hp::proliant::snmp::mode::components::ida::physical_drive($self);
    hardware::server::hp::proliant::snmp::mode::components::fca::host_array_controller($self);
    hardware::server::hp::proliant::snmp::mode::components::fca::external_array_controller($self);
    hardware::server::hp::proliant::snmp::mode::components::fca::external_array_accelerator($self);
    hardware::server::hp::proliant::snmp::mode::components::fca::logical_drive($self);
    hardware::server::hp::proliant::snmp::mode::components::fca::physical_drive($self);
    hardware::server::hp::proliant::snmp::mode::components::ide::controller($self);
    hardware::server::hp::proliant::snmp::mode::components::ide::logical_drive($self);
    hardware::server::hp::proliant::snmp::mode::components::ide::physical_drive($self);
    hardware::server::hp::proliant::snmp::mode::components::sas::controller($self);
    hardware::server::hp::proliant::snmp::mode::components::sas::logical_drive($self);
    hardware::server::hp::proliant::snmp::mode::components::sas::physical_drive($self);
    hardware::server::hp::proliant::snmp::mode::components::scsi::controller($self);
    hardware::server::hp::proliant::snmp::mode::components::scsi::logical_drive($self);
    hardware::server::hp::proliant::snmp::mode::components::scsi::physical_drive($self);
    
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
                                short_msg => sprintf("All %s components [%s] are ok - Product Name: %s, Serial: %s, Rom Version: %s", 
                                                    $total_components,
                                                    $display_by_component,
                                                    $self->{product_name}, $self->{serial}, $self->{romversion})
                                );
                                
    if (defined($self->{option_results}->{no_component}) && $total_components == 0) {
        $self->{output}->output_add(severity => $self->{no_components},
                                    short_msg => 'No components are checked.');
    }
}

sub component {
    my ($self, %options) = @_;
    
    if ($self->{option_results}->{component} eq 'cpu') {
        hardware::server::hp::proliant::snmp::mode::components::cpu::check($self);
    } elsif ($self->{option_results}->{component} eq 'psu') {
        hardware::server::hp::proliant::snmp::mode::components::psu::check($self);
    } elsif ($self->{option_results}->{component} eq 'pc') {
        hardware::server::hp::proliant::snmp::mode::components::pc::check($self);
    } elsif ($self->{option_results}->{component} eq 'fan') {
        hardware::server::hp::proliant::snmp::mode::components::fan::check($self);
    } elsif ($self->{option_results}->{component} eq 'temperature') {
        hardware::server::hp::proliant::snmp::mode::components::temperature::check($self);
    } elsif ($self->{option_results}->{component} eq 'network') {
        hardware::server::hp::proliant::snmp::mode::components::network::physical_nic($self);
        hardware::server::hp::proliant::snmp::mode::components::network::logical_nic($self);
    } elsif ($self->{option_results}->{component} eq 'storage') {
        hardware::server::hp::proliant::snmp::mode::components::ida::array_controller($self);
        hardware::server::hp::proliant::snmp::mode::components::ida::array_accelerator($self);
        hardware::server::hp::proliant::snmp::mode::components::ida::logical_drive($self);
        hardware::server::hp::proliant::snmp::mode::components::ida::physical_drive($self);
        hardware::server::hp::proliant::snmp::mode::components::fca::host_array_controller($self);
        hardware::server::hp::proliant::snmp::mode::components::fca::external_array_controller($self);
        hardware::server::hp::proliant::snmp::mode::components::fca::external_array_accelerator($self);
        hardware::server::hp::proliant::snmp::mode::components::fca::logical_drive($self);
        hardware::server::hp::proliant::snmp::mode::components::fca::physical_drive($self);
        hardware::server::hp::proliant::snmp::mode::components::ide::controller($self);
        hardware::server::hp::proliant::snmp::mode::components::ide::logical_drive($self);
        hardware::server::hp::proliant::snmp::mode::components::ide::physical_drive($self);
        hardware::server::hp::proliant::snmp::mode::components::sas::controller($self);
        hardware::server::hp::proliant::snmp::mode::components::sas::logical_drive($self);
        hardware::server::hp::proliant::snmp::mode::components::sas::physical_drive($self);
        hardware::server::hp::proliant::snmp::mode::components::scsi::controller($self);
        hardware::server::hp::proliant::snmp::mode::components::scsi::logical_drive($self);
        hardware::server::hp::proliant::snmp::mode::components::scsi::physical_drive($self);
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
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    if ($self->{option_results}->{component} eq 'all') {
        $self->global();
    } else {
        $self->component();
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub get_system_information {
    my ($self) = @_;
    
    # In 'CPQSINFO-MIB'
    my $oid_cpqSiSysSerialNum = ".1.3.6.1.4.1.232.2.2.2.1.0";
    my $oid_cpqSiProductName = ".1.3.6.1.4.1.232.2.2.4.2.0";
    my $oid_cpqSeSysRomVer = ".1.3.6.1.4.1.232.1.2.6.1.0";
    
    my $result = $self->{snmp}->get_leef(oids => [$oid_cpqSiSysSerialNum, $oid_cpqSiProductName, $oid_cpqSeSysRomVer]);
    
    $self->{product_name} = defined($result->{$oid_cpqSiProductName}) ? centreon::plugins::misc::trim($result->{$oid_cpqSiProductName}) : 'unknown';
    $self->{serial} = defined($result->{$oid_cpqSiSysSerialNum}) ? centreon::plugins::misc::trim($result->{$oid_cpqSiSysSerialNum}) : 'unknown';
    $self->{romversion} = defined($result->{$oid_cpqSeSysRomVer}) ? centreon::plugins::misc::trim($result->{$oid_cpqSeSysRomVer}) : 'unknown';
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

sub absent_problem {
    my ($self, %options) = @_;
    
    if (defined($self->{option_results}->{absent}) && 
        $self->{option_results}->{absent} =~ /(^|\s|,)($options{section}(\s*,|$)|${options{section}}[^,]*#\Q$options{instance}\E#)/) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("Component '%s' instance '%s' is not present", 
                                                         $options{section}, $options{instance}));
    }

    $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance (not present)"));
    $self->{components}->{$options{section}}->{skip}++;
    return 1;
}

1;

__END__

=head1 MODE

Check Hardware (CPUs, Power Supplies, Power converters, Fans).

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'cpu', 'psu', 'pc', 'fan', 'network', 'temperature', 'storage'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=fan,cpu)
Can also exclude specific instance: --exclude=fan#1.2#,lnic#1#,cpu

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=fan#1.2#,cpu

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=back

=cut