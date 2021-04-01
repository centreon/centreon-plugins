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

package snmp_standard::mode::swap;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_swap_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Swap Total: %s %s Used: %s %s (%.2f%%) Free: %s %s (%.2f%%)",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free});
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'swap', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{swap} = [
        { label => 'usage', nlabel => 'swap.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas => [
                    { label => 'used', value => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1 },
                ],
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'swap.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas => [
                    { label => 'free', value => 'free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1 },
                ],
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'swap.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'Used : %.2f %%',
                perfdatas => [
                    { label => 'used_prct', value => 'prct_used', template => '%.2f', min => 0, max => 100,
                      unit => '%' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'no-swap:s' => { name => 'no_swap' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{no_swap} = 'critical';
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
    
    my $oid_memTotalSwap = '.1.3.6.1.4.1.2021.4.3.0'; # KB
    my $oid_memAvailSwap = '.1.3.6.1.4.1.2021.4.4.0'; # KB
    my $result = $options{snmp}->get_leef(oids => [$oid_memTotalSwap, $oid_memAvailSwap], nothing_quit => 1);

    if ($result->{$oid_memTotalSwap} == 0) {
        $self->{output}->output_add(severity => $self->{no_swap},
                                    short_msg => 'No active swap');
        return ;
    }

    my $free = $result->{$oid_memAvailSwap} * 1024;
    my $total = $result->{$oid_memTotalSwap} * 1024;
    my $prct_used = ($total - $free) * 100 / $total;
    $self->{swap} = {
        total => $total,
        used => $total - $free,
        free => $free,
        prct_used => $prct_used,
        prct_free => 100 - $prct_used,
    };
}

1;

__END__

=head1 MODE

Check swap memory (UCD-SNMP-MIB).

=over 8

=item B<--no-swap>

Threshold if no active swap (default: 'critical').

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
