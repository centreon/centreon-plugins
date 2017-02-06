#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package hardware::server::ibm::mgmt_cards::imm::snmp::mode::environment;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

use hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::globalstatus;
use hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::temperature;
use hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::voltage;
use hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::fan;

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

    hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::globalstatus::check($self);
    hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::temperature::check($self);
    hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::voltage::check($self);
    hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::fan::check($self);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    if ($self->{option_results}->{component} eq 'all') {
        $self->global();
    } elsif ($self->{option_results}->{component} eq 'globalstatus') {
        hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::globalstatus::check($self);
    } elsif ($self->{option_results}->{component} eq 'temperature') {
        hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::temperature::check($self);
    } elsif ($self->{option_results}->{component} eq 'voltage') {
        hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::voltage::check($self);
    } elsif ($self->{option_results}->{component} eq 'fan') {
        hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::fan::check($self);
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

Check sensors (Fans, Temperatures, Voltages).

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'globalstatus', 'fan', 'temperature', 'voltage'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=temperatures,fans).

=back

=cut
    