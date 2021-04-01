#
# Copyright 2021 Centreon (http://www.centreon.com/)
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
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
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
                    { value => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'Ram Used : %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_message_output {
    my ($self, %options) = @_;

    return "Switch '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-switch-num:s' => { name => 'filter_switch_num' }
    });

    return $self;
}

my $mapping = {
    total => { oid => '.1.3.6.1.4.1.20301.2.5.1.2.12.9.1.1.3' }, # totalMemoryStatsRev
    free  => { oid => '.1.3.6.1.4.1.20301.2.5.1.2.12.9.1.1.4' } # memoryFreeStatsRev
};

my $oid_memoryStatsEntry = '.1.3.6.1.4.1.20301.2.5.1.2.12.9.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_memoryStatsEntry,
        start => $mapping->{total}->{oid},
        end => $mapping->{free}->{oid},
        nothing_quit => 1
    );

    $self->{memory} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{free}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_switch_num}) && $self->{option_results}->{filter_switch_num} ne '' &&
            $instance !~ /$self->{option_results}->{filter_switch_num}/) {
            $self->{output}->output_add(long_msg => "skipping member '" . $instance . "': no matching filter.", debug => 1);
            next;
        }

        my $prct_used = ($result->{total} - $result->{free}) * 100 / $result->{total};
        $self->{memory}->{'switch' . $instance} = {
            display => $instance,
            prct_used => $prct_used,
            prct_free => 100 - $prct_used,
            used => $result->{total} - $result->{free},
            %$result
        };
    }
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--filter-switch-num>

Filter switch number.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
