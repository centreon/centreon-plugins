#
# Copyright 2018 Centreon (http://www.centreon.com/)
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
# Contribution of YPSI SAS - (http://www.ypsi.fr)

package notification::telegram::mode::alert;

use base qw(centreon::plugins::mode);
use utf8;
use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;

my %telegram_icon_host = (
up => "\x{2705}",
down => "\x{1F525}",
unreachable => "\x{2753}",
);
my %telegram_icon_service = (
ok => "\x{2705}",
warning => "\x{26A0}",
critical => "\x{1F525}",
unknown => "\x{2753}",
);

sub new {
  my ($class, %options) = @_;
  my $self = $class->SUPER::new(package => __PACKAGE__, %options);
  bless $self, $class;

  $self->{version} = '1.0';
  $options{options}->add_options(arguments =>
  {
    "chat-id:s"             => { name => 'chat_id' },
    "bot-token:s"           => { name => 'bot_token' },
    "proxyurl:s"            => { name => 'proxyurl' },
    "proxypac:s"            => { name => 'proxypac' },
    "username:s"            => { name => 'username' },
    "password:s"            => { name => 'password' },
    "timeout:s"             => { name => 'timeout' },
    "message:s"             => { name => 'message' },
    "host-name:s"           => { name => 'host_name' },
    "host-state:s"          => { name => 'host_state' },
    "host-output:s"         => { name => 'host_output' },
    "service-description:s" => { name => 'service_description' },
    "service-state:s"       => { name => 'service_state' },
    "service-output:s"      => { name => 'service_output' },
    "graph-url:s"           => { name => 'graph_url' },
    "link-url:s"            => { name => 'link_url' },
    "centreon-url:s"        => { name => 'centreon_url' },
    "centreon-token:s"      => { name => 'centreon_token' },
  });

  $self->{http} = centreon::plugins::http->new(output => $self->{output});
  return $self;
}


sub check_options {
  my ($self, %options) = @_;

  $self->SUPER::init(%options);
  if ((!defined($self->{option_results}->{chat_id}))) {
    $self->{output}->add_option_msg(short_msg => "You need to set --chat_id option");
    $self->{output}->option_exit();
  }

  if (!defined($self->{option_results}->{bot_token})) {
    $self->{output}->add_option_msg(short_msg => "Please set the --bot_token option");
    $self->{output}->option_exit();
  }

  if (!defined($self->{option_results}->{host_name}) || $self->{option_results}->{host_name} eq '') {
    $self->{output}->add_option_msg(short_msg => "You need to specify --host-name option.");
    $self->{output}->option_exit();
  }

  foreach (('graph_url', 'link_url')) {
    if (defined($self->{option_results}->{$_})) {
      $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{option_results}->{$1}/g;
      eval "\$self->{option_results}->{\$_} = \"$self->{option_results}->{$_}\"";
    }
  }

  $self->{http}->set_options(%{$self->{option_results}}, hostname => 'dummy');
}

sub host_message {

  my ($self, %options) = @_;


  my $url_host = $self->{option_results}->{host_name};


  if (defined($self->{option_results}->{host_state}) && $self->{option_results}->{host_state} ne ''  )
  {
    if (defined($telegram_icon_host{lc($self->{option_results}->{host_state})})) {
      $self->{message} = $telegram_icon_host{lc($self->{option_results}->{host_state})};
    }
  }

  $self->{message} .= " Host <i>" . $url_host."</i>";

  if (defined($self->{option_results}->{host_state}) && $self->{option_results}->{host_state} ne '') {
    $self->{message} .= ' is <b>' . $self->{option_results}->{host_state}."</b>";

  } else {
    $self->{message}.= ' alert';
  }

  if (defined($self->{option_results}->{link_url}) && $self->{option_results}->{link_url} ne '') {
    $self->{message} .= ' - <a href="' . $self->{option_results}->{link_url}.'">Link</a>';
  }

}


sub service_message {
  my ($self, %options) = @_;

  if (defined($self->{option_results}->{service_state}) && $self->{option_results}->{service_state} ne ''  )
  {
    if (defined($telegram_icon_service{lc($self->{option_results}->{service_state})})) {
      $self->{message} = $telegram_icon_service{lc($self->{option_results}->{service_state})};
    }
  }
  my $url_service = "Host: " . $self->{option_results}->{host_name} . " | Service " . $self->{option_results}->{service_description};
  $self->{message} .= " ".$url_service;

  if (defined($self->{option_results}->{service_state}) && $self->{option_results}->{service_state} ne '') {
    $self->{message} .= " is " . $self->{option_results}->{service_state};
  } else {
    $self->{message} .= " alert";
  }
  if (defined($self->{option_results}->{service_output}) && $self->{option_results}->{service_output} ne '') {
    $self->{message} .= "\n ".  $self->{option_results}->{service_output};
  }
  if (defined($self->{option_results}->{link_url}) && $self->{option_results}->{link_url} ne '') {
    $self->{message} .= "\n <a href=\"" . $self->{option_results}->{link_url}."\">Link</a>";
  }
  if (defined($self->{option_results}->{graph_url}) && $self->{option_results}->{graph_url} ne '') {
    $self->{message} .= "\n <a href=\"".$self->{option_results}->{graph_url}."\">Graph</a>";
  }

}

sub set_payload {
  my ($self, %options) = @_;

  if (defined($self->{option_results}->{service_description}) && $self->{option_results}->{service_description} ne '') {
    $self->service_message();
  } else {
    $self->host_message();
  }
}

sub format_payload {
  my ($self, %options) = @_;

  my $json = JSON::XS->new->utf8;

  my $payload = {chat_id =>$self->{option_results}->{chat_id},
  parse_mode => 'HTML',
  text=>$self->{message}};


  eval {
    $self->{payload_str} = $json->encode($payload);
  };

  if ($@) {
    $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
    $self->{output}->option_exit();
  }

}


sub run {
  my ($self, %options) = @_;

  $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
  $self->{http}->add_header(key => 'Accept', value => 'application/json');
  $self->set_payload();
  $self->format_payload();
  my $url = 'https://api.telegram.org/bot' . $self->{option_results}->{bot_token}."/sendMessage";
  my $response = $self->{http}->request(full_url => $url, method => 'POST', query_form_post => $self->{payload_str} );
  my $telegram_response;

  eval {
    $telegram_response = decode_json($response);
  };
  if ($@) {
    $telegram_response = {};
    $self->{output}->output_add(severity => 'UNKNOWN',
    short_msg => "Cannot decode json get Telegram response: $@");
  }else{

    $self->{output}->output_add(short_msg => ' message_id : ' . $telegram_response->{result}->{message_id});
  }
  $self->{output}->display(force_ignore_perfdata => 1);
  $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send Message with Telegram API.

=over 6

=item B<--chat_id>

Telegram Chat ID (Negative Integer for Group)
Use Telegram CLI for getting Chat ID

=item B<--bot_token>

Telegram Bot Token (Check Telegram Doc for Creating Bot)
https://core.telegram.org/bots#3-how-do-i-create-a-bot

=item B<--proxyurl>

Proxy URL

=item B<--proxypac>

Proxy pac file (can be an url or local file)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--ssl-opt>

Set SSL Options (--ssl-opt="SSL_version => TLSv1" --ssl-opt="SSL_verify_mode => SSL_VERIFY_NONE").

=item B<--centreon-url>

Specify the centreon url macro (could be used in link-url and graph-url option).

=item B<--centreon-token>

Specify the centreon token for autologin macro (could be used in link-url and graph-url option).

=item B<--graph-url>

Specify the graph url (Example: %{centreon_url}/include/views/graphs/generateGraphs/generateImage.php?username=myuser&token=%{centreon_token}&hostname=%{host_name}&service=%{service_description}).

=item B<--link-url>

Specify the link url (Example: %{centreon_url}/main.php?p=20201&o=svc&host_search=%{host_name}&svc_search=%{service_description})

=item B<--host-state>

Specify host server state for the alert.

=item B<--host-output>

Specify host server output message for the alert.

=item B<--host-name>

Specify host server name for the alert (Required).

=item B<--service-description>

Specify service description name for the alert.

=item B<--service-state>

Specify service state for the alert.

=item B<--service-output>

Specify service output message for the alert.

=back

=cut
