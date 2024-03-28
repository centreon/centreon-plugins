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

package centreon::common::monitoring::openmetrics::scrape;

use strict;
use warnings;
use centreon::plugins::misc;

sub parse {
    my (%options) = @_;

    my $result;
    my $response = $options{custom}->scrape();

    # # HELP windows_cpu_time_total Time that processor spent in different modes (dpc, idle, interrupt, privileged, user)
    # # TYPE windows_cpu_time_total counter
    # windows_cpu_time_total{core="0,0",mode="dpc"} 16.203125
    # windows_cpu_time_total{core="0,0",mode="idle"} 478712.59375
    # windows_cpu_time_total{core="0,0",mode="interrupt"} 26.96875
    # windows_cpu_time_total{core="0,0",mode="privileged"} 4357.109375
    # windows_cpu_time_total{core="0,0",mode="user"} 4628.8125
    # windows_cpu_time_total{core="0,1",mode="dpc"} 19.859375
    # windows_cpu_time_total{core="0,1",mode="idle"} 476795.953125
    # windows_cpu_time_total{core="0,1",mode="interrupt"} 30.46875
    # windows_cpu_time_total{core="0,1",mode="privileged"} 4909.5
    # windows_cpu_time_total{core="0,1",mode="user"} 5116.984375

    foreach my $line (split /\n/, $response) {
        if ($line =~ /^#\s(\w{4})\s(\w+)\s(.*)$/) {
            my ($key, $metric, $string) = ($1, $2, $3);
            next if (defined($options{filter_metrics}) && $options{filter_metrics} ne '' && $metric !~ /$options{filter_metrics}/g);
            $result->{metrics}->{$metric}->{lc($key)} = $string;
        } elsif ($line =~ /^[\d\/\s]*([\w.]+)(.*)?\s([\d.+-e]+)$/) {
            my ($metric, $dimensions, $value) = ($1, $2, $3);
            next if (defined($options{filter_metrics}) && $options{filter_metrics} ne '' && $metric !~ /$options{filter_metrics}/g);

            $dimensions =~ s/[{}]//g;
            $dimensions =~ s/$options{strip_chars}//g if (defined($options{strip_chars}));

            my %dimensions = $dimensions =~ /(\w+)=(?:"(.*?)")/g;

            push @{$result->{metrics}->{$metric}->{data}}, {
                value => centreon::plugins::misc::expand_exponential(value => $value),
                dimensions => \%dimensions,
                dimensions_string => $dimensions
            };
        }
    }

    # {
    #   'metrics' => {
    #     'windows_cpu_time_total' => {
    #       'help' => 'Time that processor spent in different modes (dpc, idle, interrupt, privileged, user)',
    #       'type' => 'counter'
    #       'data' => [
    #         {
    #           'dimensions' => {
    #             'core' => '0,0',
    #             'mode' => 'dpc'
    #           },
    #           'value' => '16.203125',
    #           'dimensions_string' => 'core="0,0",mode="dpc"'
    #         },
    #         {
    #           'dimensions' => {
    #             'mode' => 'idle',
    #             'core' => '0,0'
    #           },
    #           'value' => '478712.59375',
    #           'dimensions_string' => 'core="0,0",mode="idle"'
    #         },
    #         ...
    #       ]
    #     }
    #   }
    # }

    return $result->{metrics};
}

1;

__END__

=head1 MODE

Scrape metrics.

=over 8

=back

=cut
