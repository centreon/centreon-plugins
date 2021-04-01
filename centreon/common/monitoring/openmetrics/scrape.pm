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

package centreon::common::monitoring::openmetrics::scrape;

use strict;
use warnings;
use centreon::plugins::misc;

sub parse {
    my (%options) = @_;

    my $result;
    my $response = $options{custom}->scrape;

    foreach my $line (split /\n/, $response) {
        $result->{metrics}->{$1}->{type} = $2 if ($line =~ /^#\sTYPE\s(\w+)\s(.*)$/);
        $result->{metrics}->{$1}->{help} = $2 if ($line =~ /^#\sHELP\s(\w+)\s(.*)$/);

        next if ($line !~ /^[\d\/\s]*([\w.]+)(.*)?\s([\d.+-e]+)$/);
        my ($metric, $dimensions, $value) = ($1, $2, $3);

        $dimensions =~ s/[{}]//g;
        $dimensions =~ s/"/'/g;
        $dimensions =~ s/$options{strip_chars}//g if (defined($options{strip_chars}));
        my %dimensions = ();
        foreach (split /,/, $dimensions) {
            my ($key, $value) = split /=/;
            $dimensions{$key} = $value;
        }

        push @{$result->{metrics}->{$metric}->{data}}, {
            value => centreon::plugins::misc::expand_exponential(value => $value),
            dimensions => \%dimensions,
            dimensions_string => $dimensions
        };
    }

    return $result->{metrics};
}

1;

__END__

=head1 MODE

Scrape metrics.

=over 8

=back

=cut
