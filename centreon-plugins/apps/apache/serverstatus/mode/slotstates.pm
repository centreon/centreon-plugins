#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package apps::apache::serverstatus::mode::slotstates;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::httplib;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
            {
            "hostname:s"    => { name => 'hostname' },
            "port:s"        => { name => 'port', },
            "proto:s"       => { name => 'proto', default => "http" },
            "urlpath:s"     => { name => 'url_path', default => "/server-status/?auto" },
            "credentials"   => { name => 'credentials' },
            "username:s"    => { name => 'username' },
            "password:s"    => { name => 'password' },
            "proxyurl:s"    => { name => 'proxyurl' },
            "warning:s"     => { name => 'warning' },
            "critical:s"    => { name => 'critical' },
            "timeout:s"     => { name => 'timeout', default => '3' },
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
    
    if (($self->{option_results}->{proto} ne 'http') && ($self->{option_results}->{proto} ne 'https')) {
        $self->{output}->add_option_msg(short_msg => "Unsupported protocol specified '" . $self->{option_results}->{proto} . "'.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }
    if ((defined($self->{option_results}->{credentials})) && (!defined($self->{option_results}->{username}) || !defined($self->{option_results}->{password}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --username= and --password= options when --credentials is used");
        $self->{output}->option_exit();
    }

}

sub run {
    my ($self, %options) = @_;
    
    my $webcontent = centreon::plugins::httplib::connect($self);
    my $ScoreBoard = "";
    if ($webcontent =~ /^Scoreboard:\s+([^\s]+)/mi) {
        $ScoreBoard = $1;
    }
   
    my $srvLimit = length($ScoreBoard);
    my $CountOpenSlots = ($ScoreBoard =~ tr/\.//);

    my $exit = $self->{perfdata}->threshold_check(value => $CountOpenSlots,
                                                  threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Free slots: %d", $CountOpenSlots));
    $self->{output}->perfdata_add(label => "freeSlots",
                                  value => $CountOpenSlots,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0,
                                  max => $srvLimit);
    $self->{output}->perfdata_add(label => "waiting",
            value => ($ScoreBoard =~ tr/\_//));
    $self->{output}->perfdata_add(label => "starting",
            value => ($ScoreBoard =~ tr/S//));
    $self->{output}->perfdata_add(label => "reading",
            value => ($ScoreBoard =~ tr/R//));
    $self->{output}->perfdata_add(label => "sending",
            value => ($ScoreBoard =~ tr/W//));
    $self->{output}->perfdata_add(label => "keepalive",
            value => ($ScoreBoard =~ tr/K//));
    $self->{output}->perfdata_add(label => "dns_lookup",
            value => ($ScoreBoard =~ tr/D//));
    $self->{output}->perfdata_add(label => "closing",
            value => ($ScoreBoard =~ tr/C//));
    $self->{output}->perfdata_add(label => "logging",
            value => ($ScoreBoard =~ tr/L//));
    $self->{output}->perfdata_add(label => "gracefuly_finished",
            value => ($ScoreBoard =~ tr/G//));
    $self->{output}->perfdata_add(label => "idle_cleanup_worker",
            value => ($ScoreBoard =~ tr/I//));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Apache WebServer Slots informations

=over 8

=item B<--hostname>

IP Address or FQDN of the webserver host

=item B<--port>

Port used by Apache

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Protocol used http or https

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/server-status/?auto')

=item B<--credentials>

Specify this option if you access server-status page over basic authentification

=item B<--username>

Specify username for basic authentification (Mandatory if --credentials is specidied)

=item B<--password>

Specify password for basic authentification (Mandatory if --credentials is specidied)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--warning>

Warning Threshold on remaining free slot

=item B<--critical>

Critical Threshold on remaining free slot

=back

=cut
