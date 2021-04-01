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

package apps::github::mode::stats;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "hostname:s"        => { name => 'hostname', default => 'api.github.com' },
        "port:s"            => { name => 'port', default => '443'},
        "proto:s"           => { name => 'proto', default => 'https' },
        "timeout:s"         => { name => 'timeout' },
        "owner:s"           => { name => 'owner' },
        "repository:s"      => { name => 'repository' },
    });

    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{repository})) {
        $self->{output}->add_option_msg(short_msg => "Please set the repository option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{owner})) {
        $self->{output}->add_option_msg(short_msg => "Please set the owner option");
        $self->{output}->option_exit();
    }

    $self->{option_results}->{url_path} = "/repos/" . $self->{option_results}->{owner} . "/" . $self->{option_results}->{repository};
    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;

    my $jsoncontent = $self->{http}->request();

    my $json = JSON->new;
    my $webcontent;
    eval {
        $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    my $watchers = $webcontent->{subscribers_count};
    my $forks = $webcontent->{forks_count};
    my $stars = $webcontent->{watchers_count};

    $self->{output}->output_add(severity => "OK",
                                short_msg => sprintf("%d forks - %d watchers - %d stars", $forks, $watchers, $stars));

    $self->{output}->perfdata_add(label => 'forks',
                                  value => $forks, 
                                  min => 0);
    $self->{output}->perfdata_add(label => 'watchers',
                                  value => $watchers,
                                  min => 0);
    $self->{output}->perfdata_add(label => 'stars',
                                  value => $stars,
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check GitHub's statistics

=over 8

=item B<--hostname>

IP Addr/FQDN of the GitHub's status website (Default: status.github.com)

=item B<--port>

Port used by GitHub's status website (Default: '443')

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--urlpath>

Set path to get GitHub's status information (Default: '/repo/:owner/:repository')

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=back

=cut
