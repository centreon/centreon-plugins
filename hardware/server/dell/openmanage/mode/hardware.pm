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

package hardware::server::dell::openmanage::mode::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use hardware::server::dell::openmanage::mode::components::globalstatus;
use hardware::server::dell::openmanage::mode::components::fan;
use hardware::server::dell::openmanage::mode::components::psu;
use hardware::server::dell::openmanage::mode::components::temperature;
use hardware::server::dell::openmanage::mode::components::cpu;
use hardware::server::dell::openmanage::mode::components::cachebattery;
use hardware::server::dell::openmanage::mode::components::memory;
use hardware::server::dell::openmanage::mode::components::physicaldisk;
use hardware::server::dell::openmanage::mode::components::logicaldrive;
use hardware::server::dell::openmanage::mode::components::esmlog;
use hardware::server::dell::openmanage::mode::components::battery;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "exclude:s"        => { name => 'exclude' },
                                  "component:s"      => { name => 'component', default => 'all' },
                                });

    $self->{product_name} = undef;
    $self->{components} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub global {
    my ($self, %options) = @_;

    $self->get_system_information();
    hardware::server::dell::openmanage::mode::components::globalstatus::check($self);
    hardware::server::dell::openmanage::mode::components::fan::check($self);
    hardware::server::dell::openmanage::mode::components::psu::check($self);
    hardware::server::dell::openmanage::mode::components::temperature::check($self);
    hardware::server::dell::openmanage::mode::components::cpu::check($self);
    hardware::server::dell::openmanage::mode::components::cachebattery::check($self);
    hardware::server::dell::openmanage::mode::components::memory::check($self);
    hardware::server::dell::openmanage::mode::components::physicaldisk::check($self);
    hardware::server::dell::openmanage::mode::components::logicaldrive::check($self);
    hardware::server::dell::openmanage::mode::components::esmlog::check($self);
    hardware::server::dell::openmanage::mode::components::battery::check($self);

    my $total_components = 0;
    my $display_by_component = '';
    my $display_by_component_append = '';
    foreach my $comp (keys %{$self->{components}}) {
        # Skipping short msg when no components
        next if ($self->{components}->{$comp}->{total} == 0);
        $total_components += $self->{components}->{$comp}->{total};
        $display_by_component .= $display_by_component_append . $self->{components}->{$comp}->{total} . ' ' . $self->{components}->{$comp}->{name};
        $display_by_component_append = ', ';
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %s components [%s] are ok - Product Name: %s",
                                                    $total_components,
                                                    $display_by_component,
                                                    $self->{product_name})
                                );
}

sub component {
    my ($self, %options) = @_;

    if ($self->{option_results}->{component} eq 'globalstatus') {
        hardware::server::dell::openmanage::mode::components::globalstatus::check($self);
    } elsif ($self->{option_results}->{component} eq 'fan') {
        hardware::server::dell::openmanage::mode::components::fan::check($self);
    } elsif ($self->{option_results}->{component} eq 'psu') {
        hardware::server::dell::openmanage::mode::components::psu::check($self);
    } elsif ($self->{option_results}->{component} eq 'temperature') {
        hardware::server::dell::openmanage::mode::components::temperature::check($self);
    } elsif ($self->{option_results}->{component} eq 'cpu') {
        hardware::server::dell::openmanage::mode::components::cpu::check($self);
    } elsif ($self->{option_results}->{component} eq 'cachebattery') {
        hardware::server::dell::openmanage::mode::components::cachebattery::check($self);
    } elsif ($self->{option_results}->{component} eq 'memory') {
        hardware::server::dell::openmanage::mode::components::memory::check($self);
    } elsif ($self->{option_results}->{component} eq 'physicaldisk') {
        hardware::server::dell::openmanage::mode::components::physicaldisk::check($self);
    } elsif ($self->{option_results}->{component} eq 'logicaldrive') {
        hardware::server::dell::openmanage::mode::components::logicaldrive::check($self);
    } elsif ($self->{option_results}->{component} eq 'esmlog') {
        hardware::server::dell::openmanage::mode::components::esmlog::check($self);
    } elsif ($self->{option_results}->{component} eq 'battery') {
        hardware::server::dell::openmanage::mode::components::battery::check($self);
    }else {
        $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find component '" . $self->{option_results}->{component} . "'.");
        $self->{output}->option_exit();
    }

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
                                short_msg => sprintf("All %s components [%s] are ok.",
                                                     $total_components,
                                                     $display_by_component)
                                );
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
    
    # In '10892-MIB'
    my $oid_chassisModelName = ".1.3.6.1.4.1.674.10892.1.300.10.1.9.1";
    
    my $result = $self->{snmp}->get_leef(oids => [$oid_chassisModelName]);
    
    $self->{product_name} = defined($result->{$oid_chassisModelName}) ? centreon::plugins::misc::trim($result->{$oid_chassisModelName}) : 'unknown';
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

Check Hardware (Global status, Fans, CPUs, Power Supplies, Temperature Probes, Cache Batteries).

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'globalstatus', 'fan', 'cpu', 'psu', 'temperature', 'cachebattery', 'physicaldisk', 'logicaldrive', 'battery'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=psu,fan).

=back

=cut
    
