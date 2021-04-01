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

package cloud::aws::cloudwatchlogs::mode::getlogs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'log [created: %s] [stream: %s] [message: %s] ',
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{since}),
        $self->{result_values}->{stream_name},
        $self->{result_values}->{message}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'alarms', type => 2, message_multiple => '0 logs detected', display_counter_problem => { label => 'logs', min => 0 },
          group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ] 
        }
    ];

    $self->{maps_counters}->{alarm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'message' }, { name => 'stream_name' }, { name => 'since' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'group-name:s'       => { name => 'group_name' },
        'stream-name:s@'     => { name => 'stream_name' },
        'start-time-since:s' => { name => 'start_time_since' },
        'unknown-status:s'   => { name => 'unknown_status', default => '' },
        'warning-status:s'   => { name => 'warning_status', default => '' },
        'critical-status:s'  => { name => 'critical_status', default => '' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{group_name}) || $self->{option_results}->{group_name} eq '') { 
        $self->{output}->add_option_msg(short_msg => 'please set --group-name option');
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{start_time_since}) && $self->{option_results}->{start_time_since} =~ /(\d+)/) {
        $self->{start_time} = time() - $1;
    }

    $self->{stream_names} = undef;
    if (defined($self->{option_results}->{stream_name})) {
        foreach my $stream_name (@{$self->{option_results}->{stream_name}}) {
            if ($stream_name ne '') {
                $self->{stream_names} = [] if (!defined($self->{stream_names}));
                push @{$self->{stream_names}}, $stream_name;
            }
        }
    }

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
    if (!defined($self->{start_time})) {
        $self->{statefile_cache}->check_options(%options);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $current_time = time();
    if (!defined($self->{start_time})) {
        $self->{statefile_cache}->read(
            statefile =>
                'cache_aws_' . $self->{mode} . '_' . $options{custom}->get_region() .
                (defined($self->{option_results}->{group_name}) ? md5_hex($self->{option_results}->{group_name}) : md5_hex('all')) . '_' .
                (defined($self->{stream_names}) ? md5_hex(join('-', @{$self->{stream_names}})) : md5_hex('all'))
        );
        $self->{start_time} = $self->{statefile_cache}->get(name => 'last_time');
        $self->{statefile_cache}->write(data => { last_time => $current_time });

        if (!defined($self->{start_time})) {
            $self->{output}->output_add(
                severity => 'OK',
                short_msg => 'first execution. create cache'
            );
            $self->{output}->display();
            $self->{output}->exit();
        }
    }

    $self->{alarms}->{global} = { alarm => {} };
    my $results = $options{custom}->cloudwatchlogs_filter_log_events(
        group_name => $self->{option_results}->{group_name},
        stream_names => $self->{stream_names},
        start_time => $self->{start_time} * 1000
    );

    my $i = 1;
    foreach my $entry (@$results) {
        $entry->{message} =~ s/[\|\n]/ -- /msg;
        $self->{alarms}->{global}->{alarm}->{$i} = {
            message => $entry->{message},
            stream_name => $entry->{logStreamName},
            since => int($current_time - ($entry->{timestamp} / 1000))
        };
        $i++;
    }
}

1;

__END__

=head1 MODE

Check cloudwatch logs.

=over 8

=item B<--group-name>

Set log group name (Required).

=item B<--stream-name>

Filters the results to only logs from the log stream (multiple option).

=item B<--start-time-since>

Lookup logs last X seconds ago.
If not set: lookup logs since the last execution. 

=item B<--unknown-status>

Set unknown threshold for status (Default: '')
Can used special variables like: %{message}, %{stream_name}, %{since}

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{message}, %{stream_name}, %{since}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{message}, %{stream_name}, %{since}

=back

=cut
