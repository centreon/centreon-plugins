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

package notification::smseagle::restapi::mode::ringalert;

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
        "date:s"                 => { name => 'date' },
        "duration:s"             => { name => 'duration' },
        "priority:s"             => { name => 'priority' },
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

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{date})
        && $self->{option_results}->{date} !~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/) {
        $self->{output}->add_option_msg(short_msg => "--date format not YYYY-MM-DDThh:mm:ssZ");
        $self->{output}->option_exit();
    }

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{duration})
        && $self->{option_results}->{duration} !~ /^[0-9]+$/) {
        $self->{output}->add_option_msg(short_msg => "--duration must be a valid number");
        $self->{output}->option_exit();
    }

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{priority})
        && $self->{option_results}->{priority} !~ /^[0-9]{1}$/) {
        $self->{output}->add_option_msg(short_msg => "--priority must be between 0 - 9");
        $self->{output}->option_exit();
    }

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{modem_no})
        && $self->{option_results}->{modem_no} !~ /^[0-8]{1}$/) {
        $self->{output}->add_option_msg(short_msg => "--modem-no must be between 0 - 8");
        $self->{output}->option_exit();
    }
}

sub set_payload($$) {
    my $self = shift;

    my $body_obj = {
        to => [ $self->{option_results}->{to} ]
    };

    $body_obj->{date} = $self->{option_results}->{date} if defined($self->{option_results}->{date});
    $body_obj->{duration} = int($self->{option_results}->{duration}) if defined($self->{option_results}->{duration});
    $body_obj->{priority} = int($self->{option_results}->{priority}) if defined($self->{option_results}->{priority});
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
    $self->write_log("[INFO] new ring alert: To=$self->{option_results}->{to}");
    my $endpoint = 'calls/ring';

    my ($response, $http_status_code, $api_response) = $options{custom}->request_api(
        method   => 'POST',
        body     => $json,
        endpoint => $endpoint
    );

    if ($response == 1) {
        my $msg = "";
        if ($http_status_code >= 400) {
            $msg = "[ERROR] Could not send ring alert $endpoint. Response: $api_response";
            $self->{output}->add_option_msg(short_msg => $msg);
            $self->write_log($msg);
            $self->{output}->exit();
        }

        $msg = "[INFO] HTTP Status: $http_status_code\nResponse: $api_response";
        $self->write_log($msg);

        $self->{output}->output_add(short_msg => $msg);
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);

    } else {
        my $msg = "Could not send ring alert $endpoint. $api_response";
        $self->write_log($msg);
        $self->{output}->add_option_msg(short_msg => $msg);
        $self->{output}->option_exit();
    }

    $self->{output}->exit();
}

1;

__END__

=head1 MODE

start a ring alert via smseagle

Example
centreon_plugins.pl --plugin=notification::smseagle::restapi::plugin --mode=ring-alert --hostname=smseagle.local --api-version=v2 --api-path=/api --access-token=123456 --to='<phonenumber>'

=over 8

=item B<--to>

Specify the phone number of the receiver of the SMS

=item B<--date>

Date when to make a call. If this parameter is not null, the call will be scheduled for the given date and time.
Must be string <YYYY-MM-DDThh:mm:ssZ>

=item B<--duration>

Duration of call (in seconds). Default 20

=item B<--priority>

Call priority. Default 0

=item B<--modem-no>

Sending modem number (only for multi modem devices)
Must be a number between 0-8

=item B<--response-log-dir>

If set the a response log will be written to specified directory

=back

=cut
