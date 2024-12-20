#
# Copyright 2022 Centreon (http://www.centreon.com/)
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
# Authors : Roman Morandell - i-Vertix
#

package notification::smseagle::restapi::mode::smsalert;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON;
use POSIX;
use URI::Encode;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "to:s"                   => { name => 'to' },
        "message-pattern:s"      => { name => 'message_pattern' },
        "host-name:s"            => { name => 'host_name' },
        "host-state:s"           => { name => 'host_state' },
        "service-description:s"  => { name => 'service_description' },
        "service-state:s"        => { name => 'service_state' },
        "event-short-datetime:s" => { name => 'event_short_datetime' },
        "priority:s"             => { name => 'priority' },
        "encoding:s"             => { name => 'encoding', default => 'standard' },
        "date:s"                 => { name => 'date' },
        "validity:s"             => { name => 'validity', default => 'max' },
        "send-after:s"           => { name => 'send_after' },
        "send-before:s"          => { name => 'send_before' },
        "test:s"                 => { name => 'test' },
        "modem-no:s"             => { name => 'modem_no' },
        "response-log-dir:s"     => { name => 'response_log_dir' }
    });

    $options{options}->add_help(package => __PACKAGE__, sections => 'SMS Eagle API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{response_log_dir})) {
        if (!-e $self->{option_results}->{response_log_dir} && !mkdir $self->{option_results}->{response_log_dir}) {
            $self->{output}->add_option_msg(short_msg => "Please specify a valid response_log_dir");
            $self->{output}->option_exit();
        }
    }

    if (centreon::plugins::misc::is_empty($self->{option_results}->{to})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --to option.");
        $self->{output}->option_exit();
    }

    if (centreon::plugins::misc::is_empty($self->{option_results}->{message_pattern})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --message-pattern option.");
        $self->{output}->option_exit();
    } else {
        $self->{option_results}->{message_pattern} =~ s/%\{(.*?)\}/$self->{option_results}->{$1}/eg;
    }

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{date})
        && $self->{option_results}->{date} !~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/) {
        $self->{output}->add_option_msg(short_msg => "--date format not YYYY-MM-DDThh:mm:ssZ");
        $self->{output}->option_exit();
    }

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{priority})
        && $self->{option_results}->{priority} !~ /^[0-9]{1}$/) {
        $self->{output}->add_option_msg(short_msg => "--priority must be between 0 - 9");
        $self->{output}->option_exit();
    }

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{encoding})
        && $self->{option_results}->{encoding} !~ /^unicode|standard$/) {
        $self->{output}->add_option_msg(short_msg => "--encoding not supported. Available default, unicode, standard");
        $self->{output}->option_exit();
    }

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{validity})
        && $self->{option_results}->{validity} !~ /^max|5m|10m|30m|1h|2h|4h|12h|1d|2d|5d|1w|2w|4w$/) {
        $self->{output}->add_option_msg(short_msg =>
            "--validity not supported. Available max, 5m, 10m, 30m, 1h, 2h, 4h, 12h, 1d, 2d, 5d, 1w, 2w, 4w");
        $self->{output}->option_exit();
    }

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{send_after})
        && $self->{option_results}->{send_after} !~ /^\d{2}:\d{2}$/) {
        $self->{output}->add_option_msg(short_msg => "--send-after not in format hh:mm");
        $self->{output}->option_exit();
    }

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{send_before})
        && $self->{option_results}->{send_before} !~ /^\d{2}:\d{2}$/) {
        $self->{output}->add_option_msg(short_msg => "--send-before not in format hh:mm");
        $self->{output}->option_exit();
    }

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{modem_no})
        && $self->{option_results}->{modem_no} !~ /^[0-8]{1}$/) {
        $self->{output}->add_option_msg(short_msg => "--modem_no must be between 0 - 8");
        $self->{output}->option_exit();
    }
}

sub set_payload($$) {
    my $self = shift;

    $self->{option_results}->{orig_message_pattern} = $self->{option_results}->{message_pattern};
    $self->{option_results}->{message_pattern} =~ s/\\n/\x0A/g;

    my $body_obj = {
        to   => [ $self->{option_results}->{to} ],
        text => $self->{option_results}->{message_pattern}
    };

    $body_obj->{date} = $self->{option_results}->{date} if defined($self->{option_results}->{date});
    $body_obj->{priority} = int($self->{option_results}->{priority}) if defined($self->{option_results}->{priority});
    $body_obj->{encoding} = $self->{option_results}->{encoding} if defined($self->{option_results}->{encoding});
    $body_obj->{validity} = $self->{option_results}->{validity} if defined($self->{option_results}->{validity});
    $body_obj->{send_after} = $self->{option_results}->{send_after} if defined($self->{option_results}->{send_after});
    $body_obj->{send_before} = $self->{option_results}->{send_before} if defined($self->{option_results}->{send_before});
    $body_obj->{test} = JSON::true if defined($self->{option_results}->{test});
    $body_obj->{modem_no} = int($self->{option_results}->{modem_no}) if defined($self->{option_results}->{modem_no});

    my $encoded;
    eval {
        $encoded = encode_json($body_obj);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
        $self->{output}->option_exit();
    }

    return ($encoded);
}

sub write_log($) {
    my $self = shift;
    my ($content) = @_;

    if (defined($self->{option_results}->{response_log_dir})) {
        my $log_file = "$self->{option_results}->{response_log_dir}/smseagle-notification.log";

        open FILE, '>>', $log_file;
        my $log = strftime('%Y-%m-%d %H:%M:%S', localtime) . " - $content\n";
        print FILE "$log";
        close FILE;
    }
}

sub run {
    my ($self, %options) = @_;

    my $json = $self->set_payload();
    $self->write_log("[INFO] new SMS alert: To=$self->{option_results}->{to}, Body=$self->{option_results}->{orig_message_pattern}");
    my $endpoint = 'messages/sms';

    my ($response, $http_status_code, $api_response) = $options{custom}->request_api(
        method   => 'POST',
        body     => $json,
        endpoint => $endpoint
    );

    if ($response == 1) {
        my $msg = "";
        if ($http_status_code >= 400) {
            $msg = "[ERROR] Could not send SMS alert. HTTP Status: $http_status_code. Response: $api_response";
            $self->{output}->add_option_msg(short_msg => $msg);
            $self->write_log($msg);
            $self->{output}->exit();
        }

        $msg = "[INFO] HTTP Status: $http_status_code\nResponse: $api_response";
        $self->write_log($msg);

        $self->{output}->output_add(short_msg => $msg);
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);

    } else {
        my $msg = "Could not send SMS alert $endpoint. $api_response";
        $self->write_log($msg);
        $self->{output}->add_option_msg(short_msg => $msg);
        $self->{output}->option_exit();
    }

    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send an SMS alert via smseagle

Example
centreon_plugins.pl --plugin=notification::smseagle::restapi::plugin --mode=sms-alert --hostname=smseagle.local --api-version=v2 --api-path=/api --access-token=123456 --to='<phonenumber>' --message-pattern='Alarm:Host %{host_name} %{host_state} since %{event_short_datetime}' --host-name=host123 --host-state=DOWN --short-datetime='01.01.2024 01:00:00'

=over 8

=item B<--to>

Specify the phone number of the receiver of the SMS

=item B<--message-pattern>

Message pattern used in the SMS. Can contain text and the variables %{host_name}, %{host_state}, %{service_description}, %{service_state}, %{event_short_datetime}.
This variables will be replaced with the corresponding options --host-name, --host-state, --service-description, --service-state and --short-datetime

=item B<--host-name>

Hostname of the affected host or service problem

=item B<--host-state>

State of the host

=item B<--service-description>

Service description of the affected service problem

=item B<--service-state>

State of the service

=item B<--event-short-datetime>

DateTime when the problem occurred

=item B<--date>

Date when to send the SMS. If this parameter is not null SMS will be scheduled for sending at the given date and time.
Must be string <YYYY-MM-DDThh:mm:ssZ>

=item B<--priority>

SMS with higher priority will be queued earlier.
Must be a number between 0-9

=item B<--encoding>

Encoding for SMS.
Can be 'unicode', 'standard'. Default 'standard'

=item B<--validity>

How long will be the message valid. If message expires before it is received by a phone, the message will be discarded by cellular network.
Can be C<5m> C<10m> C<30m> C<1h> C<2h> C<4h> C<12h> C<1d> C<2d> C<5d> C<1w> C<2w> C<4w> C<max>. Default C<max>

=item B<--send-after>

Send a message after a specified time. It can be used to prevent messages from being sent at night.
Must be string <hh:mm>

=item B<--send-before>

Send a message before a specified time. It can be used to prevent messages from being sent at night.
Must be string <hh:mm>

=item B<--test>

Simulate message sending. Messages with that parameter will not be added to outbox and they will return ID = 0.

=item B<--modem-no>

Sending modem number (only for multi modem devices)
Must be a number between 0-8

=item B<--response-log-dir>

If set the a response log will be written to specified directory

=back

=cut
