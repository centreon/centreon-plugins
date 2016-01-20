#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package storage::hp::lefthand::mode::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use storage::hp::lefthand::mode::components::fan;
use storage::hp::lefthand::mode::components::rcc;
use storage::hp::lefthand::mode::components::temperature;
use storage::hp::lefthand::mode::components::psu;
use storage::hp::lefthand::mode::components::voltage;
use storage::hp::lefthand::mode::components::device;
use storage::hp::lefthand::mode::components::rc;
use storage::hp::lefthand::mode::components::ro;

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
    
    storage::hp::lefthand::mode::components::fan::check($self);
    storage::hp::lefthand::mode::components::rcc::check($self);
    storage::hp::lefthand::mode::components::temperature::check($self);
    storage::hp::lefthand::mode::components::psu::check($self);
    storage::hp::lefthand::mode::components::voltage::check($self);
    storage::hp::lefthand::mode::components::device::check($self);
    storage::hp::lefthand::mode::components::rc::check($self);
    storage::hp::lefthand::mode::components::ro::check($self);
}

sub component {
    my ($self, %options) = @_;
    
    if ($self->{option_results}->{component} eq 'fan') {
        storage::hp::lefthand::mode::components::fan::check($self);
    } elsif ($self->{option_results}->{component} eq 'rcc') {
        storage::hp::lefthand::mode::components::rcc::check($self);
    } elsif ($self->{option_results}->{component} eq 'temperature') {
        storage::hp::lefthand::mode::components::temperature::check($self);
    } elsif ($self->{option_results}->{component} eq 'psu') {
        storage::hp::lefthand::mode::components::psu::check($self);
    } elsif ($self->{option_results}->{component} eq 'voltage') {
        storage::hp::lefthand::mode::components::voltage::check($self);
    } elsif ($self->{option_results}->{component} eq 'device') {
        storage::hp::lefthand::mode::components::device::check($self);
    } elsif ($self->{option_results}->{component} eq 'rc') {
        storage::hp::lefthand::mode::components::rc::check($self);
    } elsif ($self->{option_results}->{component} eq 'ro') {
        storage::hp::lefthand::mode::components::ro::check($self);
    } else {
        $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find component '" . $self->{option_results}->{component} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->get_global_information();
    
    if ($self->{option_results}->{component} eq 'all') {
        $self->global();
    } else {
        $self->component();
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

sub get_global_information {
    my ($self) = @_;
    
    $self->{global_information} = $self->{snmp}->get_leef(oids => [
                 '.1.3.6.1.4.1.9804.3.1.1.2.1.110.0', # fancount
                 '.1.3.6.1.4.1.9804.3.1.1.2.1.90.0', # raid controlle cache count
                 '.1.3.6.1.4.1.9804.3.1.1.2.1.120.0', # temperature sensor
                 '.1.3.6.1.4.1.9804.3.1.1.2.1.130.0', # powersupply
                 '.1.3.6.1.4.1.9804.3.1.1.2.1.140.0', # voltage sensor
                 '.1.3.6.1.4.1.9804.3.1.1.2.4.1.0', # storage device
                 '.1.3.6.1.4.1.9804.3.1.1.2.4.3.0', # raid controller
                 '.1.3.6.1.4.1.9804.3.1.1.2.4.50.0' # raid internal
                ], nothing_quit => 1);
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

Check Hardware (fans, power supplies, temperatures, voltages, raid controller caches, devices, raid controllers, raid os).

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'fan', 'rcc', 'temperature', 'psu', 'voltage', 'device', 'rc', 'ro'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=psu,rcc).

=back

=cut
    