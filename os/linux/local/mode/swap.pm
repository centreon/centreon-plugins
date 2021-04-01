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

package os::linux::local::mode::swap;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_swap_output {
    my ($self, %options) = @_;
    
    return sprintf(
        'Swap Total: %s %s Used: %s %s (%.2f%%) Free: %s %s (%.2f%%)',
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
        { name => 'swap', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{swap} = [
        { label => 'usage', nlabel => 'swap.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas => [
                    { label => 'used', template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'swap.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas => [
                    { label => 'free', template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'swap.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'Swap used: %.2f %%',
                perfdatas => [
                    { label => 'used_prct', template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'no-swap:s' => { name => 'no_swap' }
    });

    $self->{no_swap} = 'critical';
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);
    if (defined($self->{option_results}->{no_swap}) && $self->{option_results}->{no_swap} ne '') {
        if ($self->{output}->is_litteral_status(status => $self->{option_results}->{no_swap}) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong --no-swap status '" . $self->{option_results}->{no_swap} . "'.");
            $self->{output}->option_exit();
        }
        $self->{no_swap} = $self->{option_results}->{no_swap};
    }

}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'cat',
        command_options => '/proc/meminfo 2>&1'
    );

    my ($total_size, $swap_free);
    foreach (split(/\n/, $stdout)) {
        if (/^SwapTotal:\s+(\d+)/i) {
            $total_size = $1 * 1024;
        } elsif (/^SwapFree:\s+(\d+)/i) {
            $swap_free = $1 * 1024;
        }
    }
    
    if (!defined($total_size) || !defined($swap_free)) {
        $self->{output}->add_option_msg(short_msg => "Some information missing.");
        $self->{output}->option_exit();
    }

    if ($total_size == 0) {
        $self->{output}->output_add(
            severity => $self->{no_swap},
            short_msg => 'No active swap.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    my $swap_used = $total_size - $swap_free;
    my $prct_used = $swap_used * 100 / $total_size;
    my $prct_free = 100 - $prct_used;
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
    my ($swap_used_value, $swap_used_unit) = $self->{perfdata}->change_bytes(value => $swap_used);
    my ($swap_free_value, $swap_free_unit) = $self->{perfdata}->change_bytes(value => ($total_size - $swap_used));

    $self->{swap} = {
        used => $swap_used,
        free => $swap_free,
        prct_used => $prct_used,
        prct_free => $prct_free,
        total => $total_size
    };
}

1;

__END__

=head1 MODE

Check swap memory (need '/proc/meminfo' file).

Command used: cat /proc/meminfo 2>&1

=over 8

=item B<--no-swap>

Threshold if no active swap (default: 'critical').

=item B<--warning-*> B<--critical-*>

Threshold, can be 'usage' (in Bytes), 'usage-free' (in Bytes), 'usage-prct' (%).

=back

=cut
