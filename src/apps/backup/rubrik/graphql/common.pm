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

package apps::backup::rubrik::graphql::common;

use strict;
use warnings;

use Exporter 'import';

use centreon::plugins::misc qw/date_xm_ago_utc format_opt/;

our @EXPORT_OK = qw/check_compliance_timerange
                    is_uuid
                    period_to_date
                    timerange_check_options
                    $timerange_filters/;

our $timerange_filters = {
        'start-time:s'           => { name => 'start_time',           default => '' },
        'end-time:s'             => { name => 'end_time',             default => '' },
        'last:s'                 => { name => 'last',                 default => '' }
};

sub timerange_check_options {
    my ($obj, %options) = @_;

    my $prefix = $options{prefix} // '';
    $prefix .= '_' if $prefix;
    my $start = $prefix.'start_time';
    my $end = $prefix.'end_time';
    my $last = $prefix.'last';

    $obj->{output}->option_exit(short_msg => 'Cannot use --'.format_opt($start).'/--'.format_opt($end).' with --'.format_opt($last))
        if ($obj->{option_results}->{$start} ne '' || $obj->{option_results}->{$end} ne '') && $obj->{option_results}->{$last} ne '';

    if ($obj->{option_results}->{$start} eq '' && $obj->{option_results}->{$end} eq '' && $obj->{option_results}->{$last} ne '') {
        $obj->{output}->option_exit(short_msg => 'Invalid --'.format_opt($last).' value. Expected format: <duration>[unit], where unit is m, h, or d (default: h)')
            if $obj->{option_results}->{$last} !~ /^\d+[mhd]?$/i;
        $obj->{option_results}->{$start} = period_to_date($obj->{option_results}->{$last}, 'd', 1);
    } else {
        # Expected format: YYYY-MM-DD HH:mm:ss or YYYY-MM-DD or YYYY-MM-DDTHH:mm:ssZ
        $obj->{output}->option_exit(short_msg => 'Invalid --'.format_opt($start)." date. Expected format: 'YYYY-MM-DD HH:mm:ss' or 'YYYY-MM-DD'")
            if $obj->{option_results}->{$start} ne '' && $obj->{option_results}->{$start} !~ /^\d{4}-\d{2}-\d{2}(?:[ T]\d{2}:\d{2}:\d{2})?Z?$/;
        $obj->{output}->option_exit(short_msg => 'Invalid --'.format_opt($end)." date. Expected format: 'YYYY-MM-DD HH:mm:ss' or 'YYYY-MM-DD'")
            if $obj->{option_results}->{$end} ne '' && $obj->{option_results}->{$end} !~ /^\d{4}-\d{2}-\d{2}(?:[ T]\d{2}:\d{2}:\d{2})?Z?$/;
    }

}

sub period_to_date($;$;$)
{
    my ($value, $default_unit, $default) = @_;

    $default_unit //= 'h';

    return $default unless $value =~ /^(\d+)([mhd])?$/i;

    $value = $1; # numeric value
    my $unit = lc ($2 // $default_unit);
    if ($unit eq 'h') {
        $value *= 60;
    } elsif ($unit eq 'd') {
        $value *= 1440;
    }

    return $value;
}

# Return 1 if $data is a UUID
sub is_uuid($) {
    my ($data) = @_;

    return $data =~ /^[a-z\d]+-[a-z\d]+-[a-z\d]+-[a-z\d]+/;
}

my %compliance_timerange_values = ( 'LAST_24_HOURS' => 1, 'LAST_2_SNAPSHOTS' => 1, 'LAST_3_SNAPSHOTS' => 1,
                                    'LAST_SNAPSHOT' => 1, 'PAST_30_DAYS' => 1, 'PAST_7_DAYS' => 1,
                                    'PAST_90_DAYS' => 1, 'SINCE_PROTECTION' => 1 );

sub check_compliance_timerange {
    my (%options) = @_;

    my $timerange = uc $options{timerange};

    return 1, "OK" if $timerange eq '';

    return 0, "Invalid timerange value. Expected value: ".join ',', map { "'$_'" } sort keys %compliance_timerange_values
        unless exists $compliance_timerange_values{$timerange};

    return 1, "OK";
}


1;
