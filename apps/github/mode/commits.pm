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

package apps::github::mode::commits;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON;
use DateTime;

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
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);

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

    $self->{option_results}->{url_path} = "/repos/" . $self->{option_results}->{owner} . "/" . $self->{option_results}->{repository}."/commits";
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;

    $self->{statefile_value}->read(statefile => 'github_' . $self->{option_results}->{repository} . '_' . $self->{option_results}->{owner} . '_' . $self->{http}->get_port() . '_' . $self->{mode});
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');

    my $new_datas = {};
    $new_datas->{last_timestamp} = time();
    $self->{statefile_value}->write(data => $new_datas);

    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }

    # Change date format from epoch to iso8601
    my $old_iso8601 = DateTime->from_epoch(epoch => $old_timestamp)."Z";

    my $jsoncontent = $self->{http}->request(get_param => ['per_page=1000', 'since=' . $old_iso8601]);

    my $json = JSON->new;
    my $webcontent;
    eval {
        $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    # Number of commits is array length
    my $nb_commits = @{$webcontent};

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Number of commits : %d", $nb_commits));
    $self->{output}->perfdata_add(label => "commits",
                                  value => $nb_commits,
                                  min => 0
                                 );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check GitHub's number of commits for a repository

=over 8

=item B<--hostname>

IP Addr/FQDN of the GitHub's API (Default: api.github.com)

=item B<--port>

Port used by GitHub's API (Default: '443')

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=item B<--owner>

Specify GitHub's owner

=item B<--repository>

Specify GitHub's repository

=back

=cut
