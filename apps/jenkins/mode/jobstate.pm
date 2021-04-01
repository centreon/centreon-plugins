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

package apps::jenkins::mode::jobstate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "hostname:s"           => { name => 'hostname' },
        "port:s"               => { name => 'port' },
        "proto:s"              => { name => 'proto' },
        "urlpath:s"            => { name => 'url_path' },
        "timeout:s"            => { name => 'timeout' },
        "credentials"          => { name => 'credentials' },
        "basic"                => { name => 'basic' },
        "username:s"           => { name => 'username' },
        "password:s"           => { name => 'password' },
        "jobname:s"            => { name => 'jobname' },
        "warning:s"            => { name => 'warning' },
        "critical:s"           => { name => 'critical' },
        "checkstyle"           => { name => 'checkstyle' },
    });

    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{jobname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the jobname option");
        $self->{output}->option_exit();
    }
    
    $self->{option_results}->{url_path} = $self->{option_results}->{url_path} . "/job/" . $self->{option_results}->{jobname} . "/api/json";
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

    my $description_tendency = $webcontent->{healthReport}->[0]->{description};
    my $score_tendency = $webcontent->{healthReport}->[0]->{score};

    my ($description_violations, $number_violations);

    my $exit1 = $self->{perfdata}->threshold_check(value => $score_tendency, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);


    $self->{output}->output_add(severity => $exit1,
        short_msg => sprintf("%s", $description_tendency));
    $self->{output}->perfdata_add(label => 'score_tendency',
        value => sprintf("%d", $score_tendency),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min => 0,
    );

    if (defined($self->{option_results}->{checkstyle})) {
        if (defined($webcontent->{healthReport}->[1]->{description})) {
            my $description_violations;
            my $number_violations;
            $description_violations = $webcontent->{healthReport}->[1]->{description};
                if ( $description_violations =~ /^.+?([0-9]+)$/ ) {
                    $number_violations = $1;
                }

            $self->{output}->add_option_msg(short_msg => sprintf("%s", $description_violations));
            $self->{output}->perfdata_add(label => 'number_violations',
                value => sprintf("%d", $number_violations),
                min => 0,
            );
        }
    }

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Jenkins specific job tendency (score) and checkstyle violation

=over 8

=item B<--hostname>

IP Addr/FQDN of the Jenkins host

=item B<--port>

Port used by Jenkins API

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--urlpath>

Set path to get Jenkins information

=item B<--credentials>

Required to use username/password authentication method

=item B<--basic>

Specify this option if you access API over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your webserver.

Specify this option if you access API over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(Use with --credentials)

=item B<--username>

Specify username for API authentification

=item B<--password>

Specify password for API authentification

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=item B<--warning>

Warning Threshold for tendency score

=item B<--critical>

Critical Threshold for tendency score

=item B<--checkstyle>

Add checkstyle's violation output and perfdata

=back

=cut
