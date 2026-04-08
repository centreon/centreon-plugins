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

package apps::saas::apivideo::restapi::mode::videosusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'time offset %d second(s): %s',
        $self->{result_values}->{offset},
        $self->{result_values}->{date}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'offset', type => 0 }
    ];

    $self->{maps_counters}->{offset} = [
        {
            label => 'ntp-status',
            type => 2,
            critical_default => '%{status} !~ /in_reach|in_sync/i',
            set => {
                key_values => [ { name => 'status' } ],
                output_template => 'ntp status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'offset', nlabel => 'time.offset.seconds', set => {
                key_values => [ { name => 'offset' }, { name => 'date' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', unit => 's' }
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

sub get_target_time {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        endpoint => '/api/system',
        get_param => ['properties=system_time,ntp_server_status']
    );
    if (!defined($result->{system_time})) {
        $self->{output}->add_option_msg(short_msg => "Cannot find time informations");
        $self->{output}->option_exit();
    }

    my $tz = {};
    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    }

    my $dt = DateTime->from_epoch(epoch => $result->{system_time} / 1000, %$tz);

    return ($dt->epoch(), $dt->iso8601(), $result->{ntp_server_status});
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'rubrik_' . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        md5_hex($self->{option_results}->{cluster_id});

    my $last_timestamp = $self->read_statefile_key(key => 'last_timestamp');
    $last_timestamp = time() - (5 * 60) if (!defined($last_timestamp));
    my $timespan = POSIX::ceil((time() - $last_timestamp) / 60);
    $timespan = 1 if ($timespan <= 0);

    my $name = $options{custom}->request_api(endpoint => '/cluster/' . $self->{option_results}->{cluster_id} . '/name');
    my $status = $options{custom}->request_api(endpoint => '/cluster/' . $self->{option_results}->{cluster_id} . '/system_status');
    my $io_stats = $options{custom}->request_api(
        endpoint => '/cluster/' . $self->{option_results}->{cluster_id} . '/io_stats',
        get_param => ['range=-' . $timespan . 'min']
    );

    $self->{clusters} = {
        $name => {
            name => $name,
            status => $status->{status}
        }
    };

    foreach my $entry ((
        ['ioThroughput', 'readBytePerSecond', 'read'], ['ioThroughput', 'writeBytePerSecond', 'write'],
        ['iops', 'readsPerSecond', 'read_iops'], ['iops', 'writesPerSecond', 'write_iops']
    )) {
        my $count = 0;
        foreach (@{$io_stats->{ $entry->[0] }->{ $entry->[1] }}) {
            $self->{clusters}->{$name}->{ $entry->[2] } = 0
                if (!defined($self->{clusters}->{$name}->{ $entry->[2] }));
            $self->{clusters}->{$name}->{ $entry->[2] } += $_->{stat};
            $count++;
        }
        $self->{clusters}->{$name}->{ $entry->[2] } = int($self->{clusters}->{$name}->{ $entry->[2] } / $count) if ($count > 0);
    }
}

1;

__END__

=head1 MODE

Check videos usage.

=over 8

=item B<--unknown-ntp-status>

Define the conditions to match for the status to be UNKNOWN.

=item B<--warning-ntp-status>

Define the conditions to match for the status to be WARNING.

=item B<--critical-ntp-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /in_reach|in_sync/i')
You can use the following variables: %{status}

=item B<--warning-offset>

Define the time offset (in seconds) that will trigger a WARNING status.

=item B<--critical-offset>

Define the time offset (in seconds) that will trigger a CRITICAL status.

=back

=cut
