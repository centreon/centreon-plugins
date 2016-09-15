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

package hardware::ats::apc::mode::psu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    1 => ['atsPowerSupplyFailure', 'CRITICAL'],
    2 => ['atsPowerSupplyOK', 'OK'],
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
    $self->{snmp} = $options{snmp};

    my $oid_atsStatus5VPowerSupply = '.1.3.6.1.4.1.318.1.1.8.5.1.5.0';
    my $oid_atsStatus24VPowerSupply = '.1.3.6.1.4.1.318.1.1.8.5.1.6.0';
    my $oid_atsStatus24VSourceBPowerSupply = '.1.3.6.1.4.1.318.1.1.8.5.1.7.0';
    my $oid_atsStatusPlus12VPowerSupply = '.1.3.6.1.4.1.318.1.1.8.5.1.8.0';
    my $oid_atsStatusMinus12VPowerSupply = '.1.3.6.1.4.1.318.1.1.8.5.1.9.0';

    $self->{results} = $self->{snmp}->get_leef(oids => [$oid_atsStatus5VPowerSupply, $oid_atsStatus24VPowerSupply, $oid_atsStatus24VSourceBPowerSupply, $oid_atsStatusPlus12VPowerSupply, $oid_atsStatusMinus12VPowerSupply], nothing_quit => 1);

    my $exit1 = ${$states{$self->{results}->{$oid_atsStatus5VPowerSupply}}}[1];
    my $exit2 = ${$states{$self->{results}->{$oid_atsStatus24VPowerSupply}}}[1];
    my $exit3 = ${$states{$self->{results}->{$oid_atsStatus24VSourceBPowerSupply}}}[1];
    my $exit4 = ${$states{$self->{results}->{$oid_atsStatusPlus12VPowerSupply}}}[1];
    my $exit5 = ${$states{$self->{results}->{$oid_atsStatusMinus12VPowerSupply}}}[1];

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All power supplies are ok');

    $self->{output}->output_add(long_msg => sprintf("Power supply 5V state is '%s'", ${$states{$self->{results}->{$oid_atsStatus5VPowerSupply}}}[0]));
    $self->{output}->output_add(long_msg => sprintf("Power supply 24V state for source A is '%s'", ${$states{$self->{results}->{$oid_atsStatus24VPowerSupply}}}[0]));
    $self->{output}->output_add(long_msg => sprintf("Power supply 24V state for source B is '%s'", ${$states{$self->{results}->{$oid_atsStatus24VSourceBPowerSupply}}}[0]));
    $self->{output}->output_add(long_msg => sprintf("Power supply +12V state is '%s'", ${$states{$self->{results}->{$oid_atsStatusPlus12VPowerSupply}}}[0]));
    $self->{output}->output_add(long_msg => sprintf("Power supply -12V state is '%s'", ${$states{$self->{results}->{$oid_atsStatusMinus12VPowerSupply}}}[0]));
    
    if (!$self->{output}->is_status(value => $exit1, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit1,
                                short_msg => sprintf("Power supply 5V state is '%s'", ${$states{$self->{results}->{$oid_atsStatus5VPowerSupply}}}[0]));
    }
    if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit2,
                                short_msg => sprintf("Power supply 24V state for source A is '%s'", ${$states{$self->{results}->{$oid_atsStatus24VPowerSupply}}}[0]));
    }
    if (!$self->{output}->is_status(value => $exit3, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit3,
                                short_msg => sprintf("Power supply 24V state for source B is '%s'", ${$states{$self->{results}->{$oid_atsStatus24VSourceBPowerSupply}}}[0]));
    }
    if (!$self->{output}->is_status(value => $exit4, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit4,
                                short_msg => sprintf("Power supply +12V state is '%s'", ${$states{$self->{results}->{$oid_atsStatusPlus12VPowerSupply}}}[0]));
    }
    if (!$self->{output}->is_status(value => $exit5, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit5,
                                short_msg => sprintf("Power supply -12V state is '%s'", ${$states{$self->{results}->{$oid_atsStatusMinus12VPowerSupply}}}[0]));
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check APC ATS power supplies.

=over 8

=back

=cut
    
