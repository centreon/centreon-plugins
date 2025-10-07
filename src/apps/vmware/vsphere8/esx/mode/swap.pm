#
# Copyright 2025 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package apps::vmware::vsphere8::esx::mode::swap;
use strict;
use warnings;
use base qw(apps::vmware::vsphere8::esx::mode);

my @counters = (
    'mem.swap.current.HOST',
    'mem.swap.target.HOST',
    #'mem.swap.readrate.HOST', # pushed in manage_selection if necessary
    #'mem.swap.writerate.HOST' # pushed in manage_selection if necessary
);

sub custom_swap_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Swap usage: %s %s (max available is %s %s)",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_bytes}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{max_bytes})
    );
    return $msg;
}

sub custom_swap_read_rate_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Swap read rate is: %s %s/s",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{read_rate_bps})
    );
    return $msg;
}
sub custom_swap_write_rate_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Swap write rate is: %s %s/s",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{write_rate_bps})
    );
    return $msg;
}

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options);

    $options{options}->add_options(
        arguments => {
            'add-rates' => { name => 'add_rates' }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    # If a threshold is given on rates, we enable the corresponding data collection
    if (grep {$_ =~ /rate/ && defined($self->{option_results}->{$_}) && $self->{option_results}->{$_} ne ''} keys %{$self->{option_results}}) {
        $self->{option_results}->{add_rates} = 1;
    }
}

# Skip rates processing if there is no available data
sub skip_rates {
    my ($self, %options) = @_;

    return 0 if (defined($self->{swap_rates})
        && ref($self->{swap_rates}) eq 'HASH'
        && scalar(keys %{$self->{swap_rates}}) > 0);

    return 1;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'swap_usage', type => 0 },
        { name => 'swap_rates', type => 0, cb_init => 'skip_rates' }
    ];

    $self->{maps_counters}->{swap_usage} = [
        {
            label  => 'usage-bytes',
            type   => 1,
            nlabel => 'swap.usage.bytes',
            set    => {
                key_values            => [ { name => 'used_bytes' }, { name => 'max_bytes' }, { name => 'used_prct' } ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas             => [ { value => 'used_bytes', template => '%s', unit => 'B', max => 'max_bytes' } ]
            },
        },
        {
            label  => 'usage-prct',
            type   => 1,
            nlabel => 'swap.usage.percent',
            set    => {
                key_values      => [ { name => 'used_prct' } ],
                output_template => "Percent used: %.2f%%",
                output_use      => 'used_prct',
                perfdatas       => [ { value => 'used_prct', template => '%s', unit => '%', min => 0, max => 100 } ]
            }
        }
    ];

    $self->{maps_counters}->{swap_rates} = [
        {
            label  => 'read-rate-bps',
            type   => 1,
            nlabel => 'swap.read-rate.bytespersecond',
            set    => {
                closure_custom_output => $self->can('custom_swap_read_rate_output'),
                key_values            => [ { name => 'read_rate_bps' } ],
                perfdatas             => [ { value => 'read_rate_bps', template => '%s', unit => 'Bps' } ]
            }
        },
        {
            label  => 'write-rate-bps',
            type   => 1,
            nlabel => 'swap.write-rate.bytespersecond',
            set    => {
                closure_custom_output => $self->can('custom_swap_write_rate_output'),
                key_values            => [ { name => 'write_rate_bps' } ],
                perfdatas             => [ { value => 'write_rate_bps', template => '%s', unit => 'Bps' } ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    push @counters, 'mem.swap.readrate.HOST', 'mem.swap.writerate.HOST' if ($self->{option_results}->{add_rates});

    my %results = map {
        $_ => $self->get_esx_stats(%options, cid => $_, esx_id => $self->{esx_id}, esx_name => $self->{esx_name})
    } @counters;

    if (!defined($results{'mem.swap.current.HOST'}) || !defined($results{'mem.swap.target.HOST'})) {
        $self->{output}->option_exit(short_msg => "get_esx_stats function failed to retrieve stats");
    }

    $self->{swap_usage} = {
        used_bytes => $results{'mem.swap.current.HOST'} * 1024,
        max_bytes  => $results{'mem.swap.target.HOST'} * 1024,
        used_prct  => $results{'mem.swap.target.HOST'} ? 100 * $results{'mem.swap.current.HOST'} / $results{'mem.swap.target.HOST'} : 0
    };

    $self->{swap_rates}->{read_rate_bps}  = $results{'mem.swap.readrate.HOST'} * 1024 if defined($results{'mem.swap.readrate.HOST'});
    $self->{swap_rates}->{write_rate_bps} = $results{'mem.swap.writerate.HOST'} * 1024 if defined($results{'mem.swap.writerate.HOST'});

    return 1;
}

1;

=head1 MODE

Monitor the swap usage of VMware ESX hosts through vSphere 8 REST API.

    Meaning of the available counters in the VMware API:
    - mem.swap.current.HOST     Amount (in kB) of memory that is used by swap. Sum of memory swapped of all powered on VMs and vSphere services on the host.
    - mem.swap.target.HOST      Target size (in kB) for the virtual machine swap file. The VMkernel manages swapping by comparing swaptarget against swapped.
    - mem.swap.readrate.HOST    Rate (in kB/s) at which memory is swapped from disk into active memory during the interval. This counter applies to virtual machines and is generally more useful than the swapin counter to determine if the virtual machine is running slow due to swapping, especially when looking at real-time statistics.
    - mem.swap.writerate.HOST   Rate (in kB/s) at which memory is being swapped from active memory to disk during the current interval. This counter applies to virtual machines and is generally more useful than the swapout counter to determine if the virtual machine is running slow due to swapping, especially when looking at real-time statistics.

=over 8

=item B<--add-rates>

Add counters related to swap read and write rates.
This option is implicitly enabled if thresholds related to rates are set.

=item B<--warning-read-rate-bps>

Threshold in bytes per second.

=item B<--critical-read-rate-bps>

Threshold in bytes per second.

=item B<--warning-usage-bytes>

Threshold in B.

=item B<--critical-usage-bytes>

Threshold in B.

=item B<--warning-usage-prct>

Threshold in percentage.

=item B<--critical-usage-prct>

Threshold in percentage.

=item B<--warning-write-rate-bps>

Threshold in bytes per second.

=item B<--critical-write-rate-bps>

Threshold in bytes per second.

=back

=cut
