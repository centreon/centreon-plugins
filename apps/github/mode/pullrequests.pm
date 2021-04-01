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

package apps::github::mode::pullrequests;

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
        "port:s"            => { name => 'port', default => '443' },
        "proto:s"           => { name => 'proto', default => 'https' },
        "timeout:s"         => { name => 'timeout' },
        "warning:s"         => { name => 'warning' },
        "critical:s"        => { name => 'critical' },
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
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
    
    $self->{option_results}->{url_path} = "/repos/".$self->{option_results}->{owner}."/".$self->{option_results}->{repository}."/pulls";
    $self->{option_results}->{get_param} = ['state=open', 'per_page=1000'];
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
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    # Number of pull requests is array length
    my $nb_pulls = @{$webcontent};

    my $exit = $self->{perfdata}->threshold_check(value => $nb_pulls, threshold => [ { label => 'critical', exit_litteral => 'critical' }, , { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("%d pull requests are open", $nb_pulls ));
    $self->{output}->perfdata_add(label => 'pullrequests',
                                  value => $nb_pulls,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0
                                 );
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check GitHub's number of pull requests for a repository

=over 8

=item B<--hostname>

IP Addr/FQDN of the GitHub's API (Default: api.gitub.com)

=item B<--port>

Port used by GitHub's API (Default: '443')

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--owner>

Specify GitHub's owner

=item B<--repository>

Specify GitHub's repository

=back

=cut
