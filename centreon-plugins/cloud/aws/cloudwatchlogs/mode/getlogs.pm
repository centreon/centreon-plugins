#
# Copyright 2020 Centreon (http://www.centreon.com/)
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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'log [created: %s] [stream: %s] [message: %s] ',
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{since}),
        $self->{result_values}->{stream_name},
        $self->{result_values}->{message}
    );
    return $msg;
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
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'group-name:s'      => { name => 'group_name' },
        'stream-names:s@'   => { name => 'stream_names' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '' },
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

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
    $self->{statefile_cache}->check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{statefile_cache}->read(
        statefile =>
            'cache_aws_' . $self->{mode} . '_' . $options{custom}->get_region() .
            (defined($self->{option_results}->{group_name}) ? md5_hex($self->{option_results}->{group_name}) : md5_hex('all')) . '_' .
            (defined($self->{option_results}->{stream_names}) ? md5_hex(join(',' . $self->{option_results}->{stream_names})) : md5_hex('all'))
    );
    my $last_time = $self->{statefile_cache}->get(name => 'last_time');
    my $current_time = time();
    $self->{statefile_cache}->write(data => { last_time => $current_time });

    if (defined($last_time)) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => 'first execution. create cache'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    $self->{alarms}->{global} = { alarm => {} };
    my $results = $options{custom}->cloudwatchlogs_filter_log_events(
        group_name => $self->{option_results}->{group_name},
        stream_names => $self->{option_results}->{stream_names},
        start_time => $last_time * 1000
    );

    my $i = 1;
    foreach (@$results) {
        $self->{alarms}->{global}->{alarm}->{$i} = { 
            message => $_->{message},
            stream_name => $_->{logStreamName},
            since => int($current_time - ($_->{timestamp} / 1000))
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

Filters the results to only logs from the log streams (multiple option).

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
