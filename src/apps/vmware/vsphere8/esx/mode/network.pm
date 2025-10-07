#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::esx::mode::network;
use strict;
use warnings;
use base qw(apps::vmware::vsphere8::esx::mode);

my @counters = (
    #'net.throughput.provisioned.HOST',     # not used atm
    'net.throughput.usable.HOST',
    'net.throughput.usage.HOST',
    #'net.throughput.contention.HOST'       # pushed in manage_selection if necessary
);

sub custom_network_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Network throughput usage: %s %s/s of %s %s/s usable",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{usage_bps}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{max_bps})
    );
    return $msg;
}

# Skip contention processing if there is no available data
sub skip_contention {
    my ($self, %options) = @_;

    return 0 if (defined($self->{contention})
        && ref($self->{contention}) eq 'HASH'
        && scalar(keys %{$self->{contention}}) > 0);

    return 1;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'network', type => 0 },
        { name => 'contention', type => 0, cb_init => 'skip_contention' }

    ];

    $self->{maps_counters}->{network} = [
        {
            label      => 'usage-bps',
            type       => 1,
            nlabel     => 'network.throughput.usage.bytespersecond',
            set        => {
                key_values            => [ { name => 'usage_bps' }, { name => 'max_bps' }, { name => 'usage_prct' } ],
                closure_custom_output => $self->can('custom_network_output'),
                perfdatas             => [ { value => 'usage_bps', template => '%s', unit => 'Bps', min => 0,  max => 'max_bps' } ]
            }
        },
        {
            label      => 'usage-prct',
            type       => 1,
            nlabel     => 'network.throughput.usage.percent',
            set        => {
                key_values            => [ { name => 'usage_prct' } ],
                output_template => "%.2f%% of usable network throughput used",
                output_use      => "usage_prct",
                perfdatas             => [ { value => 'usage_prct', template => '%s', unit => '%', min => 0, max => '100' } ]
            }
        }
    ];

    $self->{maps_counters}->{contention} = [
        {
            label  => 'contention-count',
            type   => 1,
            nlabel => 'network.throughput.contention.count',
            set    => {
                key_values      => [ { name => 'net.throughput.contention.HOST' } ],
                output_template => "%d packet(s) dropped",
                output_use      => "net.throughput.contention.HOST",
                perfdatas       => [ { value => 'net.throughput.contention.HOST', template => '%s', unit => '' } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options);

    $options{options}->add_options(
        arguments => {
            'add-contention' => { name => 'add_contention' }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    # If a threshold is given on rates, we enable the corresponding data collection
    if (grep {$_ =~ /contention/ && defined($self->{option_results}->{$_}) && $self->{option_results}->{$_} ne ''} keys %{$self->{option_results}}) {
        $self->{option_results}->{add_contention} = 1;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    push @counters, 'net.throughput.contention.HOST' if ($self->{option_results}->{add_contention});

    my %results = map {
        $_ => $self->get_esx_stats(%options, cid => $_, esx_id => $self->{esx_id}, esx_name => $self->{esx_name} )
    } @counters;

    if (!defined($results{'net.throughput.usage.HOST'}) || !defined($results{'net.throughput.usable.HOST'})) {
        $self->{output}->option_exit(short_msg => "get_esx_stats function failed to retrieve stats");
    }

    $self->{contention} = {};
    $self->{network} = {
        usage_bps  => $results{'net.throughput.usage.HOST'} * 1024,
        max_bps    => $results{'net.throughput.usable.HOST'} * 1024,
        usage_prct => 0
    };

    $self->{network}->{usage_prct} = 100 * $results{'net.throughput.usage.HOST'} / $results{'net.throughput.usable.HOST'}
        if $results{'net.throughput.usable.HOST'};

    if ( defined($results{'net.throughput.contention.HOST'}) ) {
        $self->{contention}->{'net.throughput.contention.HOST'} = $results{'net.throughput.contention.HOST'};
    }
}

1;

=head1 MODE

Monitor the swap usage of VMware ESX hosts through vSphere 8 REST API.

    - net.throughput.provisioned.HOST      The maximum network bandwidth (in kB/s) for the host.
    - net.throughput.usable.HOST           The currently available network bandwidth (in kB/s) for the host.
    - net.throughput.usage.HOST            The current network bandwidth usage (in kB/s) for the host.
    - net.throughput.contention.HOST       The aggregate network droppped packets for the host.

=over 8

=item B<--add-contention>

Add counters related to network throughput contention.
This option is implicitly enabled if thresholds related to contention are set.

=item B<--warning-contention-count>

Threshold.

=item B<--critical-contention-count>

Threshold.

=item B<--warning-usage-bps>

Threshold in bytes per second.

=item B<--critical-usage-bps>

Threshold in bytes per second.

=item B<--warning-usage-prct>

Threshold in percentage.

=item B<--critical-usage-prct>

Threshold in percentage.

=back

=cut
