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

package network::juniper::common::junos::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_mem_output {
    my ($self, %options) = @_;

    return sprintf("Total: %s %s Used: %s %s (%.2f%%) Free: %s %s (%.2f%%)",
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
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All memories are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_mem_output'),
                perfdatas => [
                    { label => 'used', value => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_mem_output'),
                perfdatas => [
                    { label => 'free', value => 'free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'Used : %.2f %%',
                perfdatas => [
                    { label => 'used_prct', value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_memory_output {
    my ($self, %options) = @_;

    return "Memory '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter:s' => { name => 'filter', default => 'routing|fpc'}
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oid_jnxOperatingDescr = '.1.3.6.1.4.1.2636.3.1.13.1.5';
    my $oid_jnxOperatingBuffer = '.1.3.6.1.4.1.2636.3.1.13.1.11';
    my $oid_jnxOperatingMemory = '.1.3.6.1.4.1.2636.3.1.13.1.15'; # MB
    
    my $result = $options{snmp}->get_table(oid => $oid_jnxOperatingDescr, nothing_quit => 1);
    my $routing_engine_find = 0;
    my @oids_routing_engine = ();
    foreach my $oid (keys %$result) {        
        if ($result->{$oid} =~ /$self->{option_results}->{filter}/i) {
            $routing_engine_find = 1;
            push @oids_routing_engine, $oid;
        }
    }

    if ($routing_engine_find == 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot find operating with '$self->{option_results}->{filter}' in description.");
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids => [$oid_jnxOperatingBuffer, $oid_jnxOperatingMemory],
        instances => \@oids_routing_engine,
        instance_regexp => "^" . $oid_jnxOperatingDescr . '\.(.+)'
    );
    my $result2 = $options{snmp}->get_leef();
    foreach my $oid_routing_engine (@oids_routing_engine) {
        $oid_routing_engine =~ /^$oid_jnxOperatingDescr\.(.+)/;
        my $instance = $1;
        my $total_size = $result2->{$oid_jnxOperatingMemory . '.' . $instance} * 1024 * 1024;
        my $prct_used = $result2->{$oid_jnxOperatingBuffer . '.' . $instance};

        $self->{memory}->{$instance} = {
            display => $result->{$oid_jnxOperatingDescr . '.' . $instance},
            total => $total_size,
            prct_used => $prct_used,
            prct_free => 100 - $prct_used,
            used => $total_size * $prct_used / 100,
            free => $total_size - ($total_size * $prct_used / 100)
        };
    }
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--filter>

Filter operating (Default: 'routing|fpc').

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
