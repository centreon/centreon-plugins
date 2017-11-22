#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package apps::rudder::mode::global;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

sub new {
  my ($class, %options) = @_;
  my $self = $class->SUPER::new(package => __PACKAGE__, %options);
  bless $self, $class;

  $self->{version} = '1.0.0';
  $options{options}->add_options(
    arguments => {
      "hostname:s" => { name => 'hostname', default => '' },
      "port:s" => { name => 'port', default => 443 },
      "proto:s" => { name => 'proto', default => 'https' },
      "base-url:s" => { name => 'base_url', default => '/rudder' },
      "cert-file:s"   => { name => 'cert_file' },
      "authtoken:s" => { name => 'authtoken', default => '' },
      "warning:s" => { name => 'warning', default => '85' },
      "critical:s" => { name => 'critical', default => '90' }
    }
  );

  $self->{http} = centreon::plugins::http->new(output => $self->{output});
  return $self;
}

sub check_options {
  my ($self, %options) = @_;
  $self->SUPER::init(%options);

  if ($self->{option_results}->{hostname} eq '') {
    $self->{output}->add_option_msg(short_msg => "The hostname must be defined.");
    $self->{output}->option_exit();
  }
  if ($self->{option_results}->{base_url} eq '') {
    $self->{output}->add_option_msg(short_msg => "The base url must be defined.");
    $self->{output}->option_exit();
  }
  if ($self->{option_results}->{authtoken} eq '') {
    $self->{output}->add_option_msg(short_msg => "The authentication token must be defined.");
    $self->{output}->option_exit();
  }
  if (($self->{perfdata}->threshold_validate(label => 'warning', value => sprintf('%d:', $self->{option_results}->{warning}))) == 0) {
    $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{warning} . "'.");
    $self->{output}->option_exit();
  }
  if (($self->{perfdata}->threshold_validate(label => 'critical', value => sprintf('%d:', $self->{option_results}->{critical}))) == 0) {
    $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{critical} . "'.");
    $self->{output}->option_exit();
  }

  my %httpOptions;
  $httpOptions{'hostname'} = $self->{option_results}->{hostname};
  $httpOptions{'port'} = $self->{option_results}->{port};
  $httpOptions{'proto'} = $self->{option_results}->{proto};
  $httpOptions{'url_path'} = $self->{option_results}->{base_url} . '/api/latest/compliance/rules?level=1';
  if ($self->{option_results}->{cert_file}) {
    $httpOptions{'cert_file'} = $self->{option_results}->{cert_file};
  }
  $self->{http}->set_options(%httpOptions);
  my %httpHeader;
  $httpHeader{key} = 'X-API-Token';
  $httpHeader{value} = $self->{option_results}->{authtoken};
  $self->{http}->add_header(%httpHeader);
}

sub run {
  my ($self, %options) = @_;

  my $json_content = $self->{http}->request();
  my $json = JSON->new;
  my $webcontent;

  eval {
    $webcontent = $json->decode($json_content);
  };
  my $level = $webcontent->{data}->{rules}[0]->{compliance};

  my $exit1 = $self->{perfdata}->threshold_check(value => $level, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

  $self->{output}->output_add(severity => $exit1,
        short_msg => sprintf("Level of compliance %d%%", $level));
  $self->{output}->perfdata_add(label => 'compliance',
        value => sprintf("%d", $level),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min => 0,
        max => 100,
        unit => '%'
    );

  $self->{output}->display();
  $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the global compliance of a Rudder instance

=over 8

=item B<--hostname>

The Rudder hostname (required)

=item B<--port>

The Rudder http port (default: 443)

=item B<--proto>

The Rudder http protocol (default: https)

=item B<--base-url>

The base url for rudder (default: /rudder)

=item B<--cert-file>

The certificate file for self signed

=item B<--authtoken>

The authentication token

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=back

=cut
