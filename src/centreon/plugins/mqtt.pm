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

package centreon::plugins::mqtt;

use strict;
use warnings;
use Time::HiRes;
use Net::MQTT::Simple;
use Net::MQTT::Simple::SSL;

sub new {
    my ($class, %options) = @_;
    my $self              = {};
    bless $self, $class;

    if (!defined($options{noptions}) || $options{noptions} != 1) {
        $options{options}->add_options(arguments => {
            'hostname|host:s'        => { name => 'host' },
            'mqtt-port:s'            => { name => 'mqtt_port', default => 8883 },
            'mqtt-ssl:s'             => { name => 'mqtt_ssl', default => 1 },
            'mqtt-ca-certificate:s'  => { name => 'mqtt_ca_certificate' },
            'mqtt-ssl-certificate:s' => { name => 'mqtt_ssl_certificate' },
            'mqtt-ssl-key:s'         => { name => 'mqtt_ssl_key' },
            'mqtt-username:s'        => { name => 'mqtt_username' },
            'mqtt-password:s'        => { name => 'mqtt_password' },
            'mqtt-allow-insecure'    => { name => 'mqtt_allow_insecure', default => 0 },
            'mqtt-timeout:s'         => { name => 'mqtt_timeout', default => 5 }
        });
        $options{options}->add_help(package => __PACKAGE__, sections => 'MQTT GLOBAL OPTIONS');
    }

    $self->{output}         = $options{output};
    $self->{connection_set} = 0;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    if (!defined($options{option_results}->{host})) {
        $self->{output}->add_option_msg(short_msg => 'Missing parameter --hostname.');
        $self->{output}->option_exit();
    }
    $self->{mqtt_host}            = $options{option_results}->{host};
    $self->{mqtt_port}            = defined($options{option_results}->{mqtt_port}) && $options{option_results}->{mqtt_port} =~ /(\d+)/ ? $1 : 8883;
    $self->{mqtt_ssl}             = $options{option_results}->{mqtt_ssl};
    $self->{mqtt_ca_certificate}  = $options{option_results}->{mqtt_ca_certificate};
    $self->{mqtt_ssl_certificate} = $options{option_results}->{mqtt_ssl_certificate};
    $self->{mqtt_ssl_key}         = $options{option_results}->{mqtt_ssl_key};
    $self->{mqtt_username}        = $options{option_results}->{mqtt_username};
    $self->{mqtt_password}        = $options{option_results}->{mqtt_password};
    $self->{mqtt_allow_insecure}  = $options{option_results}->{mqtt_allow_insecure};
    $self->{mqtt_timeout}         = $options{option_results}->{mqtt_timeout};
}

# Prepare the MQTT connection
sub set_mqtt_options {
    my ($self, %options) = @_;

    if ($self->{connection_set} == 1) {
        return;
    }

    if (!centreon::plugins::misc::is_empty($self->{mqtt_allow_insecure}) && $self->{mqtt_allow_insecure} == 1) {
        $ENV{MQTT_SIMPLE_ALLOW_INSECURE_LOGIN} = 1;
    }

    if (!centreon::plugins::misc::is_empty($self->{mqtt_ssl}) && $self->{mqtt_ssl} == 1) {
        $self->{mqtt} = Net::MQTT::Simple::SSL->new($self->{mqtt_host}, {
            LocalPort     => $self->{mqtt_port},
            SSL_ca_file   => $self->{mqtt_ca_certificate},
            SSL_cert_file => $self->{mqtt_ssl_certificate},
            SSL_key_file  => $self->{mqtt_ssl_key}
        });
    } else {
        $self->{mqtt} = Net::MQTT::Simple->new($self->{mqtt_host} . ':' . $self->{mqtt_port});
    }
    $self->{mqtt}->login($self->{mqtt_username}, $self->{mqtt_password}) if (!centreon::plugins::misc::is_empty($self->{mqtt_username}) && !centreon::plugins::misc::is_empty($self->{mqtt_password}));

    $self->{connection_set} = 1;
}

# Query a single topic
# Returns the message
# If no message is received, the script will exit with a message indicating that no message was received in the topic
sub query {
    my ($self, %options) = @_;

    $self->set_mqtt_options(%options);

    my %mqtt_received;
    my $starttime = Time::HiRes::time();
    my $endtime   = $starttime + $self->{mqtt_timeout};
    $self->{mqtt}->subscribe($options{topic}, sub {
        my ($topic, $message)  = @_;
        $mqtt_received{$topic} = $message;
    });
    my $messages_received = 0;
    while ($messages_received == 0 and Time::HiRes::time() < $endtime) {
        $self->{mqtt}->tick(5);
        $messages_received = scalar keys %mqtt_received;
    }
    eval {
        $self->{mqtt}->unsubscribe($options{topic});
    };
    if (%mqtt_received) {
        return %mqtt_received{$options{topic}};
    } else {
        $self->{output}->add_option_msg(short_msg => 'No message in topic: ' . $options{topic});
        $self->{output}->option_exit();
    }
}

# Query multiple topics
# Returns a hash with the topics as keys and the messages as values
sub queries {
    my ($self, %options) = @_;

    $self->set_mqtt_options(%options);

    my %mqtt_received;
    foreach my $topic (@{$options{topics}}) {
        my $topic_for_query    = defined($options{base_topic}) ? $options{base_topic} . $topic : $topic;
        my $result             = $self->query(topic => $topic_for_query);
        $mqtt_received{$topic} = $result;
    }
    return %mqtt_received;
}

1;

__END__

=head1 NAME

MQTT global

=head1 SYNOPSIS

MQTT class

=head1 MQTT OPTIONS

=over 8

=item B<--hostname>

Name or address of the host to monitor (mandatory).

=item B<--mqtt-port>

Port used by MQTT (default: 8883).

=item B<--mqtt-ssl>

Use SSL for MQTT connection (default: 1).

=item B<--mqtt-ca-certificate>

CA certificate file.

=item B<--mqtt-ssl-certificate>

Client SSL certificate file.

=item B<--mqtt-ssl-key>

Client SSL key file.

=item B<--mqtt-username>

MQTT username.

=item B<--mqtt-password>

MQTT password.

=item B<--mqtt-allow-insecure>

Allow insecure login (default: 0).

=item B<--mqtt-timeout>

MQTT timeout (default: 5).

=back

=head1 DESCRIPTION

B<MQTT>.

=cut
