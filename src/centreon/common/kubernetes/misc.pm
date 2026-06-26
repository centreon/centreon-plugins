#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package centreon::common::kubernetes::misc;

use strict;
use warnings;

use Exporter 'import';
use List::Util qw/any/;
our @EXPORT_OK = qw/is_excluded_label/;

sub is_excluded_label($$$%)
{
    my ($data, $include_filters, $exclude_filters, %options) = @_;

    my ($filter_key, $filter_value);

    my $match_an_include_filter = 0;

    # Labels/annotations are filtered using both the key and the value
    foreach my $entry (
        $data->{metadata}->{labels} // {},
        $data->{metadata}->{annotations} // {},
        $data->{spec}->{template}->{metadata}->{labels} // {},
        $data->{spec}->{template}->{metadata}->{annotations} // {}
    ) {
        while (my ($key, $value) = each %$entry) {

            # As soon as an exclude filter matches we can skip the entry
            if (any {
                        # key=value, key is optional
                        /^(?:([^=]+)=)?(.+)$/;
                        ($filter_key, $filter_value) = ($1 // '', $2);
                        ($filter_key eq '' || $key =~ /$filter_key/) && $value =~ /$filter_value/
                    } @$exclude_filters) {
                $options{output}->output_add(long_msg => "skipping entry '".$options{display}."' excluded by the label/annotation filter.")
                    if %options && $options{output} && $options{output}->is_debug();
                return 1;
            }

            # All entries must be evaluated if an exclude filter is defined, even if an include filter matches
            if ($match_an_include_filter == 0 && any {
                        /^(?:([^=]+)=)?(.+)$/;
                        my ($filter_key, $filter_value) = ($1 // '', $2);
                        ($filter_key eq '' || $key =~ /$filter_key/) && $value =~ /$filter_value/;
                    } @$include_filters) {
                $match_an_include_filter = 1;
                return 0 unless @$exclude_filters;
            }
        }
    }

    if (@$include_filters && !$match_an_include_filter) {
        $options{output}->output_add(long_msg => "skipping entry '".$options{display}."' not included by the label/annotation filter.")
            if %options && $options{output} && $options{output}->is_debug();
        return 1;
    }

    return 0;
}

1;
