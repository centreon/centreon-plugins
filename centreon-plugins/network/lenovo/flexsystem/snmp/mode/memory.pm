#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::lenovo::flexsystem::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'Ram Total: %s %s Used: %s %s (%.2f%%) Free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_absolute}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_absolute}),
        $self->{result_values}->{prct_used_absolute},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_absolute}),
        $self->{result_values}->{prct_free_absolute}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_message_output', message_multiple => 'All memory usages are ok' },
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label => 'used', value => 'used_absolute', template => '%d', min => 0, max => 'total_absolute',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label => 'free', value => 'free_absolute', template => '%d', min => 0, max => 'total_absolute',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'Used : %.2f %%',
                perfdatas => [
                    { label => 'used_prct', value => 'prct_used_absolute', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_message_output {
    my ($self, %options) = @_;

    return "Switch '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter:s' => { name => 'filter', default => '.*' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_switchNumber = '.1.3.6.1.4.1.20301.2.5.1.2.12.9.1.1.1';
    my $oid_totalMemoryStatsRev = '.1.3.6.1.4.1.20301.2.5.1.2.12.9.1.1.3'; # in bytes
    my $oid_memoryFreeStatsRev = '.1.3.6.1.4.1.20301.2.5.1.2.12.9.1.1.4'; # in bytes

    my $result = $options{snmp}->get_table(oid => $oid_switchNumber, nothing_quit => 1);
    my @instance_oids = ();
    foreach my $oid (keys %$result) {
        if ($result->{$oid} =~ /$self->{option_results}->{filter}/i) {
            push @instance_oids, $oid;
        }
    }

    if (scalar(@instance_oids) == 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot find switch number '$self->{option_results}->{filter}'.");
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids => [$oid_totalMemoryStatsRev, $oid_memoryFreeStatsRev],
        instances => \@instance_oids,
        instance_regexp => "^" . $oid_switchNumber . '\.(.+)'
    );
    my $result2 = $options{snmp}->get_leef();

    foreach my $instance (@instance_oids) {
        $instance =~ /^$oid_switchNumber\.(.+)/;
        $instance = $1;

        my $free = $result2->{$oid_memoryFreeStatsRev . '.' . $instance};
        my $total = $result2->{$oid_totalMemoryStatsRev . '.' . $instance};
        my $prct_used = ($total - $free) * 100 / $total;
        $self->{memory}->{$instance} = {
            display => $result->{$oid_switchNumber . '.' . $instance},
            total => $total,
            used => $total - $free,
            free => $free,
            prct_used => $prct_used,
            prct_free => 100 - $prct_used,
        };
    }
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--filter>

Filter switch number (Default: '.*').

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
