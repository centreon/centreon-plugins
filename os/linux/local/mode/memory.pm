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

package os::linux::local::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_memory_output {
    my ($self, %options) = @_;

    return sprintf(
        'Ram total: %s %s used (-%s): %s %s (%.2f%%) free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{result_values}->{used_desc},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub custom_swap_output {
    my ($self, %options) = @_;
    
    return sprintf(
        'Swap total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)',
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
        { name => 'memory', type => 0, skipped_code => { -10 => 1 } },
        { name => 'swap', type => 0, skipped_code => { -10 => 1 } }
    ];

     $self->{maps_counters}->{memory} = [
        { label => 'memory-usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'used_desc' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B' }
                ]
            }
        },
        { label => 'memory-usage-free', nlabel => 'memory.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'used_desc' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B' }
                ]
            }
        },
        { label => 'memory-usage-prct', nlabel => 'memory.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'used_desc' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'buffer', nlabel => 'memory.buffer.bytes', set => {
                key_values => [ { name => 'buffer' } ],
                output_template => 'buffer: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'cached', nlabel => 'memory.cached.bytes', set => {
                key_values => [ { name => 'cached' } ],
                output_template => 'cached: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'slab', nlabel => 'memory.slab.bytes', set => {
                key_values => [ { name => 'slab' } ],
                output_template => 'slab: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'B' }
                ]
            }
        },
    ];

    $self->{maps_counters}->{swap} = [
        { label => 'swap', nlabel => 'swap.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas => [
                    { label => 'swap', template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'swap-free', display_ok => 0, nlabel => 'swap.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas => [
                    { label => 'swap_free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'swap-prct', display_ok => 0, nlabel => 'swap.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas => [
                    { label => 'swap_prct', template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'swap'       => { name => 'check_swap' },
        'warning:s'  => { name => 'warning', redirect => 'warning-memory-usage-percentage' },
        'critical:s' => { name => 'critical', redirect => 'critical-memory-usage-percentage' }
    });

    return $self;
}

sub check_rhel_version {
    my ($self, %options) = @_;

    $self->{rhel_71} = 0;
    return if ($options{stdout} !~ /(?:Redhat|CentOS|Red[ \-]Hat).*?release\s+(\d+)\.(\d+)/mi);
    $self->{rhel_71} = 1 if ($1 >= 8 || ($1 == 7 && $2 >= 1));
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'cat',
        command_options => '/proc/meminfo /etc/redhat-release 2>&1',
        no_quit => 1
    );

    # Buffer can be missing. In Openvz container for example.
    my $buffer_used = 0;
    my ($cached_used, $free, $total_size, $slab_used, $swap_total, $swap_free);
    foreach (split(/\n/, $stdout)) {
        if (/^MemTotal:\s+(\d+)/i) {
            $total_size = $1 * 1024;
        } elsif (/^Cached:\s+(\d+)/i) {
            $cached_used = $1 * 1024;
        } elsif (/^Buffers:\s+(\d+)/i) {
            $buffer_used = $1 * 1024;
        } elsif (/^Slab:\s+(\d+)/i) {
            $slab_used = $1 * 1024;
        } elsif (/^MemFree:\s+(\d+)/i) {
            $free = $1 * 1024;
        } elsif (/^SwapTotal:\s+(\d+)/i) {
            $swap_total = $1 * 1024;
        } elsif (/^SwapFree:\s+(\d+)/i) {
            $swap_free = $1 * 1024;
        }
    }

    if (!defined($total_size) || !defined($cached_used) || !defined($free)) {
        $self->{output}->add_option_msg(short_msg => 'Some informations missing.');
        $self->{output}->option_exit();
    }

    $self->check_rhel_version(stdout => $stdout);

    my $physical_used = $total_size - $free;
    my $nobuf_used = $physical_used - $buffer_used - $cached_used;
    if ($self->{rhel_71} == 1) {
        $nobuf_used -= $slab_used if (defined($slab_used));
    }

    my $used_desc = 'buffers/cache';
    $used_desc .= '/slab' if ($self->{rhel_71} == 1 && defined($slab_used));

    $self->{memory} = {
        total => $total_size,
        used => $nobuf_used,
        free => $total_size - $nobuf_used,
        prct_used => $nobuf_used * 100 / $total_size,
        prct_free => 100 - ($nobuf_used * 100 / $total_size),
        used_desc => $used_desc,

        buffer => $buffer_used,
        cache => $cached_used,
        slab => $slab_used
    };

    if (defined($self->{option_results}->{check_swap}) && 
        defined($swap_total) && $swap_total > 0) {
        $self->{swap} = {
            total => $swap_total,
            used => $swap_total - $swap_free,
            free => $swap_free,
            prct_used => 100 - ($swap_free * 100 / $swap_total),
            prct_free => ($swap_free * 100 / $swap_total)
        };
    }
}

1;

__END__

=head1 MODE

Check physical memory (need '/proc/meminfo' file).

Command used: cat /proc/meminfo /etc/redhat-release 2>&1

=over 8

=item B<--swap>

Check swap also.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'memory-usage' (B), 'memory-usage-free' (B), 'memory-usage-prct' (%), 
'swap' (B), 'swap-free' (B), 'swap-prct' (%),
'buffer' (B), 'cached' (B), 'slab' (B).

=back

=cut
