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

package hardware::ats::apc::mode::entity;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %switch_states = (
    1 => ['fail', 'CRITICAL'],
    2 => ['ok', 'OK'],
);

my %hardware_states = (
    1 => ['fail', 'CRITICAL'],
    2 => ['ok', 'OK'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
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

    my $oid_atsStatusSwitchStatus = '.1.3.6.1.4.1.318.1.1.8.5.1.10.0';
    my $oid_atsStatusHardwareStatus = '.1.3.6.1.4.1.318.1.1.8.5.1.16.0';

    $self->{results} = $self->{snmp}->get_leef(oids => [$oid_atsStatusSwitchStatus, $oid_atsStatusHardwareStatus], nothing_quit => 1);

    my $exit1 = ${$switch_states{$self->{results}->{$oid_atsStatusSwitchStatus}}}[1];
    my $exit2 = ${$hardware_states{$self->{results}->{$oid_atsStatusHardwareStatus}}}[1];
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Hardware state is '%s' , Switch state is '%s'", 
                                                ${$hardware_states{$self->{results}->{$oid_atsStatusHardwareStatus}}}[0], ${$switch_states{$self->{results}->{$oid_atsStatusSwitchStatus}}}[0]));
       
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check APC ATS entity (hardware and switch state).

=over 8

=back

=cut
    
