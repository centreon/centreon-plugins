#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package apps::monitoring::kadiska::mode::tracerstatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_output {
    my ($self, %options) = @_;
    
    return "Target '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'targets', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All targets are OK' }
    ];

    $self->{maps_counters}->{targets} = [
        { label => 'round-trip', nlabel => 'round.trip.persecond', set => {
                key_values => [ { name => 'round_trip' }, { name => 'display' } ],
                output_template => 'Round trip: %.2f ms',
                perfdatas => [
                    { label => 'round_trip', template => '%.2f', unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'path-length', nlabel => 'path.length', set => {
                key_values => [ { name => 'path_length' }, { name => 'display' } ],
                output_template => 'Path length: %.2f',
                perfdatas => [
                    { label => 'path_length', template => '%.2f', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'packets-loss-prct', nlabel => 'packets.loss.percentage', set => {
                key_values => [ { name => 'packets_loss_prct' }, { name => 'display' } ],
                output_template => 'Packets Loss: %.2f %%',
                perfdatas => [
                    { label => 'packets_loss_prct', template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }          
    ];
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-station-name:s' => { name => 'filter_station_name' },
        'filter-tracer:s' => { name => 'filter_tracer' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $raw_form_post = {
        "begin" => 1648456500000,
        "end" => 1651134900000,
        "select" => [
            {
                "tracer:group" => "tracer_id"
            },
            {
                "length_furthest:avg" => ["avg","length_furthest"]
            },
            {
                "loss_furthest:avg" => ["*",100,["avg","loss_furthest"]]
            },
            {
                "rtt_furthest:avg" => ["avg","rtt_furthest"]
            }
        ],
        "from" => "traceroute",
        "groupby" => [
            "tracer:group"
        ],
        "orderby" => [
            ["rtt_furthest:avg","desc"]
        ],
        "offset" => 0
    };  

    if (defined($self->{option_results}->{filter_station_name}) && $self->{option_results}->{filter_station_name} ne ''){
        $raw_form_post->{where} = ["=","station_name",["\$", $self->{option_results}->{filter_station_name}]],
    }

    my $results = $options{custom}->request_api(
        method => 'POST',
        endpoint => 'query',
        query_form_post => $raw_form_post
    );

    $self->{targets} = {};
    foreach my $watcher (@{$results->{data}}) {
        next if (defined($self->{option_results}->{filter_tracer}) && $self->{option_results}->{filter_tracer} ne ''
            && $watcher->{'tracer:group'} !~ /$self->{option_results}->{filter_tracer}/);

        my $instance = $watcher->{"tracer:group"};

        $self->{targets}->{$instance} = { display => $instance, 
                                    round_trip => ($watcher->{'rtt_furthest:avg'} / 1000),
                                    packets_loss_prct => $watcher->{'loss_furthest:avg'},
                                    path_length => $watcher->{'length_furthest:avg'},
        }
  };

}

1;

__END__

=head1 MODE

Check Kadiska tracer target statistics.

=over 8

=item B<--filter-station-name>

Filter on station name to display tracer targets' statistics linked to a particular station. 

=item B<--filter-tracer>

Filter to display statistics for particular tracer targets. Can be a regex or a single tracer target.
A tracer_id must be given. 

Regex example: 
--filter-tracer="(tracer:myid|tracer:anotherid)"

=item B<--warning-round-trip>

Warning threshold for round trip in milliseconds.

=item B<--critical-round-trip>

Critical threshold for round trip in milliseconds.

=item B<--warning-path-length>

Warning threshold for path length to reach targets. 

=item B<--critical-path-length>

Critical threshold for path length to reach targets. 

item B<--warning-packets-loss-prct>

Warning threshold for packets' loss in percentage. 

=item B<--critical-packets-loss-prct>

Critical threshold for packets' loss in percentage. 

=back

=cut
