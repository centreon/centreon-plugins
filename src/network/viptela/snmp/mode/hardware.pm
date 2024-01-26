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

package network::viptela::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:temperature)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        default => [
            ['ok', 'OK'],
            ['down', 'CRITICAL'],
            ['failed', 'CRITICAL']
        ]
    };
    
    $self->{components_path} = 'network::viptela::snmp::mode::components';
    $self->{components_module} = ['fan', 'led', 'nim', 'pem', 'pim', 'temperature', 'usb'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    my $map_status = {
        0 => 'ok', 1 => 'down', 2 => 'failed'
    };
    my $map_type = {
        0 => 'temperature', 1 => 'fan', 2 => 'pem', 3 => 'pim', 4 => 'usb', 5 => 'led', 6 => 'nim'
    };
    my $mapping = {
        status  => { oid => '.1.3.6.1.4.1.41916.3.1.2.1.4', map => $map_status }, # hardwareEnvironmentStatus
        measure => { oid => '.1.3.6.1.4.1.41916.3.1.2.1.5' } # hardwareEnvironmentMeasurement
    };
    my $table = '.1.3.6.1.4.1.41916.3.1.2'; # hardwareEnvironmentTable

    $self->{results} = [];
    my $snmp_result = $options{snmp}->get_table(oid => $table, start => $mapping->{status}->{oid});
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{status}->{oid}\.(\d+).(\d+)\.(.*?)\.(\d+)$/);
        my $type = $map_type->{$1};
        my $instance = $1 . '.' . $2 . '.' . $3 . '.' . $4;
        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $1 . '.' . $2 . '.' . $3 . '.' . $4
        );
        push @{$self->{results}}, {
            name => $self->{output}->decode(join('', map(chr($_), split(/\./, $3)))),
            type => $type,
            status => $result->{status},
            measure => $result->{measure}
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'fan', 'led', 'nim', 'pem', 'pim', 'temperature', 'usb'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=temperature).
You can also exclude items from specific instances: --filter=temperature,Board

=item B<--no-component>

Define the expected status if no components are found (default: critical).


=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='temperature,OK,down'

=item B<--warning>

Set warning threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40'

=item B<--critical>

Set critical threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,50'

=back

=cut
