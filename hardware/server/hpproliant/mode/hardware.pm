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

package hardware::server::hpproliant::mode::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use hardware::server::hpproliant::mode::components::cpu;
use hardware::server::hpproliant::mode::components::psu;
use hardware::server::hpproliant::mode::components::pc;
use hardware::server::hpproliant::mode::components::fan;
use hardware::server::hpproliant::mode::components::temperature;
use hardware::server::hpproliant::mode::components::network;
use hardware::server::hpproliant::mode::components::ida;
use hardware::server::hpproliant::mode::components::fca;
use hardware::server::hpproliant::mode::components::ide;
use hardware::server::hpproliant::mode::components::sas;
use hardware::server::hpproliant::mode::components::scsi;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "exclude"        => { name => 'exclude' },
                                });

    $self->{product_name} = undef;
    $self->{serial} = undef;
    $self->{romversion} = undef;
    $self->{components} = {};
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

    $self->get_system_information();
    hardware::server::hpproliant::mode::components::cpu::check($self);
    hardware::server::hpproliant::mode::components::psu::check($self);
    hardware::server::hpproliant::mode::components::pc::check($self);
    hardware::server::hpproliant::mode::components::fan::check($self);
    hardware::server::hpproliant::mode::components::temperature::check($self);
    hardware::server::hpproliant::mode::components::network::physical_nic($self);
    hardware::server::hpproliant::mode::components::network::logical_nic($self);
    hardware::server::hpproliant::mode::components::ida::array_controller($self);
    hardware::server::hpproliant::mode::components::ida::array_accelerator($self);
    hardware::server::hpproliant::mode::components::ida::logical_drive($self);
    hardware::server::hpproliant::mode::components::ida::physical_drive($self);
    hardware::server::hpproliant::mode::components::fca::host_array_controller($self);
    hardware::server::hpproliant::mode::components::fca::external_array_controller($self);
    hardware::server::hpproliant::mode::components::fca::external_array_accelerator($self);
    hardware::server::hpproliant::mode::components::fca::logical_drive($self);
    hardware::server::hpproliant::mode::components::fca::physical_drive($self);
    hardware::server::hpproliant::mode::components::ide::controller($self);
    hardware::server::hpproliant::mode::components::ide::logical_drive($self);
    hardware::server::hpproliant::mode::components::ide::physical_drive($self);
    hardware::server::hpproliant::mode::components::sas::controller($self);
    hardware::server::hpproliant::mode::components::sas::logical_drive($self);
    hardware::server::hpproliant::mode::components::sas::physical_drive($self);
    hardware::server::hpproliant::mode::components::scsi::controller($self);
    hardware::server::hpproliant::mode::components::scsi::logical_drive($self);
    hardware::server::hpproliant::mode::components::scsi::physical_drive($self);
    
    my $total_components = 0;
    my $display_by_component = '';
    my $display_by_component_append = '';
    foreach my $comp (sort(keys %{$self->{components}})) {
        # Skipping short msg when no components
        next if ($self->{components}->{$comp}->{total} == 0);
        $total_components += $self->{components}->{$comp}->{total};
        $display_by_component .= $display_by_component_append . $self->{components}->{$comp}->{total} . ' ' . $self->{components}->{$comp}->{name};
        $display_by_component_append = ', ';
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %s components [%s] are ok - Product Name: %s, Serial: %s, Rom Version: %s", 
                                $total_components,
                                $display_by_component,
                                $self->{product_name}, $self->{serial}, $self->{romversion}));
    
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

Check Hardware (CPUs, Power Supplies, Power converters, Fans).

=over 8

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=psu,pc).

=back

=cut
    