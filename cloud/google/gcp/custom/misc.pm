#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package cloud::google::gcp::custom::misc;

use strict;
use warnings;

sub format_metric_label {
    my (%options) = @_;

    my $metric = $options{metric};
    $metric =~ s/$options{remove}// if (defined($options{remove}) && $options{remove} ne '');
    $metric = lc($metric);
    $metric =~ s/(\/)|(_)/-/g;

    return $metric;
}

sub format_metric_perf {
    my (%options) = @_;

    my $metric = $options{metric};
    $metric =~ s/$options{remove}// if (defined($options{remove}) && $options{remove} ne '');
    $metric = lc($metric);
    $metric =~ s/\//_/g;

    return $metric;
}

sub format_metric_name {
    my (%options) = @_;

    my $metric = $options{metric};
    $metric =~ s/$options{remove}// if (defined($options{remove}) && $options{remove} ne '');
    $metric =~ s/(\/)|(_)/ /g;
    $metric =~ s/(\w+)/\u$1/g;

    return $metric;
}

1;

__END__

