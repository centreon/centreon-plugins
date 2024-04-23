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

package hardware::devices::camera::avigilon::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_memory_output {
    my ($self, %options) = @_;

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});

    return sprintf(
        'total system memory available: %s',
        $total_value . " " . $total_unit
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => 0 }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'available', nlabel => 'memory.available', set => {
            key_values      => [{ name => 'total' }],
            closure_custom_output => $self->can('custom_memory_output'),
            perfdatas       => [
                { value => 'total', template => '%d', min => 0,
                  unit  => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
            ],
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_total   = '.1.3.6.1.4.1.46202.1.1.1.6.0'; #memAvailable
    my $snmp_result = $options{snmp}->get_leef(
        oids         => [$oid_total],
        nothing_quit => 1
    );

    $self->{memory} = {
        total => $snmp_result->{$oid_total}
    };

}

1;

__END__

=head1 MODE

Check system memory available.

=over 8

=item B<--warning-available*>

Warning threshold for total memory available (B).

=item B<--critical-available*>

Critical threshold for total memory available (B).

=back

=cut
