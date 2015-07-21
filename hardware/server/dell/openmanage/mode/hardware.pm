#
# Copyright 2015 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
use hardware::server::dell::openmanage::mode::components::controller;
use hardware::server::dell::openmanage::mode::components::connector;

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
    hardware::server::dell::openmanage::mode::components::controller::check($self);
    hardware::server::dell::openmanage::mode::components::connector::check($self);

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

sub globalstatus {
    my %status = (
        1 => ['other', 'CRITICAL'],
        2 => ['unknown', 'UNKNOWN'],
        3 => ['ok', 'OK'],
        4 => ['nonCritical', 'WARNING'],
        5 => ['critical', 'CRITICAL'],
        6 => ['nonRecoverable', 'CRITICAL'],
    );

    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking global system status");
    return if ($self->check_exclude('globalstatus'));

    my $oid_globalSystemStatus = '.1.3.6.1.4.1.674.10892.1.200.10.1.2.1';
    my $result = $self->{snmp}->get_leef(oids => [$oid_globalSystemStatus], nothing_quit => 1);
    
    $self->{output}->output_add(long_msg => sprintf("Overall global status is '%s'.",
                                    ${$status{$result->{$oid_globalSystemStatus}}}[0]
                                    ));
    
    $self->{output}->output_add(severity =>  ${$status{$result->{$oid_globalSystemStatus}}}[1],
                            short_msg => sprintf("Overall global status is '%s'",
                                            ${$status{$result->{$oid_globalSystemStatus}}}[0]));
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
    } elsif ($self->{option_results}->{component} eq 'controller') {
        hardware::server::dell::openmanage::mode::components::controller::check($self);
    } elsif ($self->{option_results}->{component} eq 'connector') {
        hardware::server::dell::openmanage::mode::components::connector::check($self);
    } elsif ($self->{option_results}->{component} eq 'storage') {
        hardware::server::dell::openmanage::mode::components::physicaldisk::check($self);
        hardware::server::dell::openmanage::mode::components::logicaldrive::check($self);
        hardware::server::dell::openmanage::mode::components::cachebattery::check($self);
        hardware::server::dell::openmanage::mode::components::controller::check($self);
        hardware::server::dell::openmanage::mode::components::connector::check($self);
        hardware::server::dell::openmanage::mode::components::cachebattery::check($self);
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
    } elsif ($self->{option_results}->{component} eq 'globalstatus') {
        $self->globalstatus();
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

Check Hardware (Global status, Fans, CPUs, Power Supplies, Temperature, Storage).

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'globalstatus', 'fan', 'cpu', 'psu', 'temperature', 'cachebattery', 'physicaldisk', 'logicaldrive', 'battery', 'controller', 'connector', 'storage'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=psu,fan).

=back

=cut
    
