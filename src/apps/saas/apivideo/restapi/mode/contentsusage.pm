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

package apps::saas::apivideo::restapi::mode::contentsusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);
use DateTime;

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Contents ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'played', nlabel => 'contents.played.count', set => {
                key_values => [ { name => 'play_count' } ],
                output_template => 'played: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'watch-time', nlabel => 'contents.watch_time.seconds', set => {
                key_values => [ { name => 'watchtime_sum' }, { name => 'watchtime_human' } ],
                output_template => 'watching time: %s',
                output_use => 'watchtime_human',
                perfdatas => [
                    { template => '%s', unit => 's', min => 0 }
                ]
            }
        },
        { label => 'users-concurrent-peak', nlabel => 'contents.users.concurrent.peak.count', set => {
                key_values => [ { name => 'ccv_peak' } ],
                output_template => 'concurrent users peak: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'apivideo_' . $self->{mode} . '_' . $options{custom}->get_connection_info() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('-'));

    my $ctime = time();
    my $last_timestamp = $self->read_statefile_key(key => 'last_timestamp');
    $last_timestamp = $ctime - (15 * 60) if (!defined($last_timestamp));
    
    my $dt = DateTime->from_epoch(epoch => $ctime, time_zone => 'UTC');
    my $to = sprintf("%d-%02d-%02dT%02d:%02d:%02d+00:00", $dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute, $dt->second);
    $dt->subtract(seconds => $ctime - $last_timestamp);
    my $from = sprintf("%d-%02d-%02dT%02d:%02d:%02d+00:00", $dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute, $dt->second);

    $self->{global} = {};

    my $response = $options{custom}->get_endpoint(
        endpoint => '/data/metrics/play/count',
        get_param => [
            'from=' . $from, 
            'to=' . $to
        ]
    );
    $self->{global}->{play_count} = $response->{data};

    $response = $options{custom}->get_endpoint(
        endpoint => '/data/metrics/watch-time/sum',
        get_param => [
            'from=' . $from, 
            'to=' . $to
        ]
    );
    $self->{global}->{watchtime_sum} = $response->{data};
    $self->{global}->{watchtime_human} = centreon::plugins::misc::change_seconds(value => $response->{data});

    $response = $options{custom}->get_endpoint(
        endpoint => '/data/metrics/ccv/peak',
        get_param => [
            'from=' . $from, 
            'to=' . $to
        ]
    );
    $self->{global}->{ccv_peak} = $response->{data};
}

1;

__END__

=head1 MODE

Check contents (videos, live stream) usage.

=over 8

=item B<--warning-played>

Warning threshold for contents played.

=item B<--critical-played>

Critical threshold for contents played.

=item B<--warning-watch-time>

Warning threshold for contents watching time.

=item B<--critical-watch-time>

Critical threshold for contents watching time.

=item B<--warning-users-concurrent-peak>

Warning threshold for contents concurrent users peak.

=item B<--critical-users-concurrent-peak>

Critical threshold for contents concurrent users peak.

=back

=cut
