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

package network::security::cato::networks::api::misc;

use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(mk_timeframe filter_json);

# Supported timeframes format (x = integer):
# last.PTxM: last x minutes
# last.PTxH: last x hours
# last.PxD: last x days
# last.PxM: last x months
# last.PxY: last x years
our %_timeframe_units = (
    'm' => 'last.PT%dM',
    'h' => 'last.PT%dH',
    'd' => 'last.P%dD',
    'M' => 'last.P%dM',
    'Y' => 'last.P%dY'
);

# make a timeframe argument
# value is a numeric value and unit points to the above private hash %_timeframe_units
sub mk_timeframe($$) {
    my ($value, $unit) = @_;
    $unit //= 'M';

    return undef unless exists $_timeframe_units{$unit};

    return sprintf($_timeframe_units{$unit}, $value);
}

# The goal of filter_json function is to filter a JSON data using a string based path.
# Arrays are replaced by a counter that increments according to the position.
# All elements are separated by dots.
# Array index can be replaced by a filter in the form (key=value) or (key:value).
# Example, with these data:
# {
#  'sites' => [
#    {
#      'name' => 'lib 1'
#      'status' => 'OK',
#    },
#    {
#      'name' => 'lib 2',
#      'status' => 'CRITICAL'
#    }
#  ]
# }
# Those filters will return:
#   "sites.1.name" will return "lib 2"
#   "sites.(status=OK).name" will return "lib 1"
#   "sites.0.status" will return "OK"
sub _filter_json_rec($$);
sub _filter_json_rec($$) {
    my ($data, $filters) = @_;

    return $data unless @{$filters};

    my $part = shift @{$filters};

    my @results;

    if ($part =~ /^\(([\w\.]+)[=:]([^)]+)\)$/) { # This is a filter (key=val or key:val)
        my ($filter_key, $filter_val) = ($1, $2);

        # Iterate through the remaining data to check if they match the filter
        if (ref $data eq 'ARRAY') {
            for my $elem (@$data) {
                push @results, _filter_json_rec($elem, [@$filters])
                    if ref $elem eq 'HASH' && exists $elem->{$filter_key} && $elem->{$filter_key} eq $filter_val;
            }
        } elsif (ref $data eq 'HASH') {
            push @results, _filter_json_rec($data, [@$filters])
                if exists $data->{$filter_key} && $data->{$filter_key} eq $filter_val;
        }
    } elsif ($part =~ /^\d+$/) {  # Numeric value => this is an index of an array
        push @results, _filter_json_rec($data->[$part], [@$filters])
            if ref $data eq 'ARRAY' && $part < @$data;
    } else { # Filter by key name
        push @results, _filter_json_rec($data->{$part}, [@$filters])
            if ref $data eq 'HASH' && exists $data->{$part};
    }

    return @results;
}

sub filter_json($$) {
    my ($data, $query) = @_;

    my @filters = split /\./, $query;

    # Recusively iterate through the data to retrieve those that match the filter
    return _filter_json_rec($data, \@filters);
}

1;

__END__
