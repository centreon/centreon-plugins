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

package hardware::server::hpbladechassis::mode::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use hardware::server::hpbladechassis::mode::components::enclosure;
use hardware::server::hpbladechassis::mode::components::manager;
use hardware::server::hpbladechassis::mode::components::fan;
use hardware::server::hpbladechassis::mode::components::blade;
use hardware::server::hpbladechassis::mode::components::network;
use hardware::server::hpbladechassis::mode::components::psu;
use hardware::server::hpbladechassis::mode::components::temperature;
use hardware::server::hpbladechassis::mode::components::fuse;

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
    $self->{components} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub global {
    my ($self, %options) = @_;

    hardware::server::hpbladechassis::mode::components::enclosure::check($self);
    hardware::server::hpbladechassis::mode::components::manager::check($self);
    hardware::server::hpbladechassis::mode::components::fan::check($self);
    hardware::server::hpbladechassis::mode::components::blade::check($self);
    hardware::server::hpbladechassis::mode::components::network::check($self);
    hardware::server::hpbladechassis::mode::components::psu::check($self);
    hardware::server::hpbladechassis::mode::components::temperature::check($self);
    hardware::server::hpbladechassis::mode::components::fuse::check($self);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    if ($self->{option_results}->{component} eq 'all') {
        $self->global();
    } elsif ($self->{option_results}->{component} eq 'enclosure') {
        hardware::server::hpbladechassis::mode::components::enclosure::check($self);
    } elsif ($self->{option_results}->{component} eq 'manager') {
        hardware::server::hpbladechassis::mode::components::manager::check($self, force => 1);
    } elsif ($self->{option_results}->{component} eq 'fan') {
        hardware::server::hpbladechassis::mode::components::fan::check($self);
    } elsif ($self->{option_results}->{component} eq 'blade') {
        hardware::server::hpbladechassis::mode::components::blade::check($self);
    } elsif ($self->{option_results}->{component} eq 'network') {
        hardware::server::hpbladechassis::mode::components::network::check($self);
    } elsif ($self->{option_results}->{component} eq 'psu') {
        hardware::server::hpbladechassis::mode::components::psu::check($self);
    } elsif ($self->{option_results}->{component} eq 'temperature') {
        hardware::server::hpbladechassis::mode::components::temperature::check($self);
    } elsif ($self->{option_results}->{component} eq 'fuse') {
        hardware::server::hpbladechassis::mode::components::fuse::check($self);
    } else {
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
                                                     $display_by_component
                                                    )
                                );
    
    $self->{output}->display();
    $self->{output}->exit();
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

Check Hardware (Fans, Power Supplies, Blades, Temperatures, Fuses).

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'enclosure', 'manager', 'fan', 'blade', 'network', 'psu', 'temperature', 'fuse'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=temperatures,psu).

=back

=cut
    