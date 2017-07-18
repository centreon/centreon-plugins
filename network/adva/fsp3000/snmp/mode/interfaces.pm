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

package network::adva::fsp3000::snmp::mode::interfaces;

use base qw(snmp_standard::mode::interfaces);

use strict;
use warnings;

my $instance_mode;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters} = { int => {}, global => {} };
    $self->{maps_counters}->{int}->{'090_laser-temp'} = { filter => 'add_optical',
        set => {
            key_values => [ { name => 'laser_temp' }, { name => 'display' } ],
            output_template => 'Laser Temperature : %.2f C', output_error_template => 'Laser Temperature : %.2f',
            perfdatas => [
                { label => 'laser_temp', value => 'laser_temp_absolute', template => '%.2f',
                  unit => 'C', label_extra_instance => 1, instance_use => 'display_absolute' },
            ],
        }
    };
    $self->{maps_counters}->{int}->{'091_input_power'} = { filter => 'add_optical',
        set => {
            key_values => [ { name => 'input_power' }, { name => 'display' } ],
            output_template => 'Input Power : %s dBm', output_error_template => 'Input Power : %s',
            perfdatas => [
                { label => 'input_power', value => 'input_power_absolute', template => '%s',
                  unit => 'dBm', label_extra_instance => 1, instance_use => 'display_absolute' },
            ],
        }
    };
    $self->{maps_counters}->{int}->{'091_output_power'} = { filter => 'add_optical',
        set => {
            key_values => [ { name => 'output_power' }, { name => 'display' } ],
            output_template => 'Output Power : %s dBm', output_error_template => 'Output Power : %s',
            perfdatas => [
                { label => 'output_power', value => 'output_power_absolute', template => '%s',
                  unit => 'dBm', label_extra_instance => 1, instance_use => 'display_absolute' },
            ],
        }
    };
    
    $self->SUPER::set_counters(%options);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_traffic => 1, no_errors => 1, no_cast => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                "add-optical"   => { name => 'add_optical' },
                                }
    );
    
    $instance_mode = $self;
    return $self;
}

my $oid_opticalIfDiagLaserTemp = '.1.3.6.1.4.1.2544.1.11.2.4.3.5.1.2';
my $oid_opticalIfDiagInputPower = '.1.3.6.1.4.1.2544.1.11.2.4.3.5.1.3';
my $oid_opticalIfDiagOutputPower = '.1.3.6.1.4.1.2544.1.11.2.4.3.5.1.4';

sub custom_load {
    my ($self, %options) = @_;
    
    return if (!defined($self->{option_results}->{add_optical}));
    
    $self->{snmp}->load(oids => [$oid_opticalIfDiagLaserTemp, $oid_opticalIfDiagInputPower, $oid_opticalIfDiagOutputPower], 
        instances => $self->{array_interface_selected});
}

sub custom_add_result {
    my ($self, %options) = @_;
    
    return if (!defined($self->{option_results}->{add_optical}));
    $self->{interface_selected}->{$options{instance}}->{laser_temp} = undef;
    if (defined($self->{results}->{$oid_opticalIfDiagLaserTemp . '.' . $options{instance}}) &&
        $self->{results}->{$oid_opticalIfDiagLaserTemp . '.' . $options{instance}} != -2147483648) {
        $self->{interface_selected}->{$options{instance}}->{laser_temp} = $self->{results}->{$oid_opticalIfDiagLaserTemp . '.' . $options{instance}} * 0.1;
    }
    
    $self->{interface_selected}->{$options{instance}}->{input_power} = undef;
    if (defined($self->{results}->{$oid_opticalIfDiagInputPower . '.' . $options{instance}}) &&
        $self->{results}->{$oid_opticalIfDiagInputPower . '.' . $options{instance}} != -65535) {
        $self->{interface_selected}->{$options{instance}}->{input_power} = $self->{results}->{$oid_opticalIfDiagInputPower . '.' . $options{instance}};
    }
    
    $self->{interface_selected}->{$options{instance}}->{output_power} = undef;
    if (defined($self->{results}->{$oid_opticalIfDiagOutputPower . '.' . $options{instance}}) &&
        $self->{results}->{$oid_opticalIfDiagOutputPower . '.' . $options{instance}} != -65535) {
        $self->{interface_selected}->{$options{instance}}->{output_power} = $self->{results}->{$oid_opticalIfDiagOutputPower . '.' . $options{instance}};
    }
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item B<--add-status>

Check interface status.

=item B<--add-optical>

Check interface optical.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'laser-temp', 'input-power', 'output-power'.

=item B<--critical-*>

Threshold critical.
Can be: 'laser-temp', 'input-power', 'output-power'.

=item B<--interface>

Set the interface (number expected) ex: 1,2,... (empty means 'check all interface').

=item B<--name>

Allows to use interface name with option --interface instead of interface oid index (Can be a regexp)

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--oid-filter>

Choose OID used to filter interface (default: ifName) (values: ifDesc, ifAlias, ifName).

=item B<--oid-display>

Choose OID used to display interface (default: ifName) (values: ifDesc, ifAlias, ifName).

=item B<--oid-extra-display>

Add an OID to display.

=item B<--display-transform-src>

Regexp src to transform display value.

=item B<--display-transform-dst>

Regexp dst to transform display value.

=item B<--show-cache>

Display cache interface datas.

=back

=cut
