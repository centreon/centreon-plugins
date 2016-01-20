#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package apps::protocols::radius::mode::login;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use Authen::Radius;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
         {
         "hostname:s"       => { name => 'hostname' },
         "secret:s"         => { name => 'secret' },
         "username:s"       => { name => 'username' },
         "password:s"       => { name => 'password' },
         "warning:s"        => { name => 'warning' },
         "critical:s"       => { name => 'critical' },
         "timeout:s"        => { name => 'timeout', default => '30' },
         });
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

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{secret})) {
        $self->{output}->add_option_msg(short_msg => "Please set the secret option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{username})) {
        $self->{output}->add_option_msg(short_msg => "Please set the username option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{password})) {
        $self->{output}->add_option_msg(short_msg => "Please set the password option");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $timing0 = [gettimeofday];
    
    my $radius = Authen::Radius->new(Host => $self->{option_results}->{hostname},
                                    Secret => $self->{option_results}->{secret},
                                    TimeOut => $self->{option_results}->{timeout},
                                    );


    my $authentication = $radius->check_pwd($self->{option_results}->{username}, $self->{option_results}->{password});
    
    if ($authentication != 1) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => 'Authentication failed');
    }

    my $timeelapsed = tv_interval ($timing0, [gettimeofday]);
    
    my $exit = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Response time %.3f second(s)", $timeelapsed));
    $self->{output}->perfdata_add(label => "time", unit => 's',
                                  value => sprintf('%.3f', $timeelapsed),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Connection (also login) to a Radius Server.

=over 8

=item B<--hostname>

IP Addr/FQDN of the radius host

=item B<--secret>

Secret of the radius host

=item B<--username>

Specify username for authentication

=item B<--password>

Specify password for authentication

=item B<--timeout>

Connection timeout in seconds (Default: 30)

=item B<--warning>

Threshold warning in seconds

=item B<--critical>

Threshold critical in seconds

=back

=cut
