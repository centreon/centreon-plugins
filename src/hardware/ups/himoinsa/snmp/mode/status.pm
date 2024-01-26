#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package hardware::ups::himoinsa::snmp::mode::status;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub status_long_output {
    my ($self, %options) = @_;

    return 'checking component status';
}

sub custom_status_output {
    my ($self, %options) = @_;

    return $self->{result_values}->{display} . " status: " . $self->{result_values}->{status};
}

sub custom_status_commutator_output {
    my ($self, %options) = @_;

    return $self->{result_values}->{display} . ": " . $self->{result_values}->{status};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'components', type => 3, cb_long_output => 'status_long_output', indent_long_output => '    ',
            group => [
                { name => 'motor-status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'mode-status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'transfer-pump-status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'alarm-status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'closed-commutator', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{'motor-status'} = [
         { label => 'motor-status', type => 2, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{'mode-status'} = [
         { label => 'mode-status', type => 2, set => {
                key_values => [ { name => 'status' }, { name => 'display' }  ],
                closure_custom_output => $self->can('custom_status_commutator_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{'transfer-pump-status'} = [
         { label => 'transfer-pump-status', type => 2, set => {
                key_values => [ { name => 'status' }, { name => 'display' }  ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{'alarm-status'} = [
         { label => 'alarm-status', type => 2, warning_default => '%{status} =~ /^alarm/', set => {
                key_values => [ { name => 'status' }, { name => 'display' }  ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{'closed-commutator'} = [
         { label => 'closed-commutator', type => 2, set => {
                key_values => [ { name => 'status' }, { name => 'display' }  ],
                closure_custom_output => $self->can('custom_status_commutator_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

# mapping for CEA7 and CEM7 device
my $mapping_motor_status = {
    0 => 'unknown', 1 => 'running', 2 => 'stopped'
};

my $mapping_mode_status = {
    0 => 'unknown', 4 => 'auto', 8 => 'manual', 16 => 'test', 32 => 'blocked'
};

my $mapping_transfer_pump_status = {
    0 => 'off', 64 => 'on'
};

my $mapping_alarm_status = {
    0 => 'no alarm', 128 => 'alarm'
};

my $mapping_closed_commutator = {
    0 => 'unknown', 256 => 'mains', 512 => 'genset'
};

# mapping for CEC7 device 
my $cec7_mapping_alarm_status = {
    0 => 'no alarm', 1 => 'alarm'
};

my $cec7_mapping_mode_status = {
    0 => 'unknown', 2 => 'auto', 4 => 'manual', 8 => 'test', 16 => 'blocked'
};

my $cec7_mapping_closed_commutator = {
    0 => 'unknown', 32 => 'genset', 64 => 'mains'
};

sub get_motor_status {
    my ($self, %options) = @_;

    return ($options{value} & 1) | ($options{value} & 2);
}

sub get_mode_status {
    my ($self, %options) = @_;

    return ($options{value} & 4) | ($options{value} & 8) | ($options{value} & 16)| ($options{value} & 32);
}

sub get_transfer_pump_status {
    my ($self, %options) = @_;

    return $options{value} & 64;
}

sub get_alarm_status {
    my ($self, %options) = @_;

    return $options{value} & 128;
}

sub get_closed_commutator {
    my ($self, %options) = @_;

    return ($options{value} & 256) | ($options{value} & 512);
}

sub get_cec7_alarm_status {
    my ($self, %options) = @_;

    return $options{value} & 1;
}

sub get_cec7_mode_status {
    my ($self, %options) = @_;

    return ($options{value} & 2) | ($options{value} & 4) | ($options{value} & 8) | ($options{value} & 16);
}

sub get_cec7_closed_commutator {
    my ($self, %options) = @_;

    return ($options{value} & 32) | ($options{value} & 64);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $oid_conmutationmeasuresEntry = '.1.3.6.1.4.1.41809.1.46.0';
my $oid_cec7_conmutationmeasuresEntry = '.1.3.6.1.4.1.41809.1.55.1.28.0';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(oids => [$oid_conmutationmeasuresEntry], nothing_quit => 1);

    my $motor_status = $self->get_motor_status(value => $snmp_result->{$oid_conmutationmeasuresEntry});
    my $mode_status = $self->get_mode_status(value => $snmp_result->{$oid_conmutationmeasuresEntry});
    my $transfer_pump_status = $self->get_transfer_pump_status(value => $snmp_result->{$oid_conmutationmeasuresEntry});
    my $alarm_status = $self->get_alarm_status(value => $snmp_result->{$oid_conmutationmeasuresEntry});
    my $closed_commutator = $self->get_closed_commutator(value => $snmp_result->{$oid_conmutationmeasuresEntry});

    $self->{components} = { global => {} };

    $self->{components}->{global}->{'motor-status'} = {
        status => $mapping_motor_status->{$motor_status},
        display => 'motor'
    };

    $self->{components}->{global}->{'mode-status'} = {
        status => $mapping_mode_status->{$mode_status},
        display => 'commutator mode'
    };

    $self->{components}->{global}->{'transfer-pump-status'} = {
        status => $mapping_transfer_pump_status->{$transfer_pump_status},
        display => 'transfer pump'
    };

    $self->{components}->{global}->{'alarm-status'} = {
        status => $mapping_alarm_status->{$alarm_status},
        display => 'alarm'
    };

    $self->{components}->{global}->{'closed-commutator'} = {
        status => $mapping_closed_commutator->{$closed_commutator},
        display => 'closed commutator'
    };
}

1;

__END__

=head1 MODE

Check Himoinsa device status.

=over 8

=item B<--warning-alarm-status>

Warning threshold for alarm (default: '%{status} =~ /^alarm/').
Can use special variables like: %{status}

=item B<--critical-alarm-status>

Critical threshold for alarm.
Can use special variables like: %{status}

=item B<--warning-motor-status>

Warning threshold for motor status.
Can use special variables like: %{status}

=item B<--critical-motor-status>

Critical threshold for motor status.
Can use special variables like: %{status}

=item B<--warning-mode-status>

Warning threshold for commutator mode status.
Can use special variables like: %{status}

=item B<--critical-mode-status>

Critical threshold for commutator mode status.
Can use special variables like: %{status}

=item B<--warning-closed-commutator>

Warning threshold for commutator currently closed.
Can use special variables like: %{status}

=item B<--critical-closed-commutator>

Critical threshold for commutator currently closed.
Can use special variables like: %{status}

For example if you want to get an alert if the closed commutator is mains:

--critical-closed-commutator='%{status} =~ /mains/i'

=item B<--warning-transfer-pump-status>

Warning threshold for transfer pump status.
Can use special variables like: %{status}

=item B<--critical-transfer-pump-status>

Critical threshold for transfer pump status.
Can use special variables like: %{status}

=back

=cut
