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

package apps::nginx::serverstatus::mode::requests;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;

my $maps = [
    { counter => 'accepts', output => 'Connections accepted per seconds %.2f', match => 'server accepts handled requests.*?(\d+)' },
    { counter => 'handled', output => 'Connections handled per serconds %.2f', match => 'server accepts handled requests.*?\d+\s+(\d+)' }, 
    { counter => 'requests', output => 'Requests per seconds %.2f', match => 'server accepts handled requests.*?\d+\s+\d+\s+(\d+)' },
];

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "hostname:s"        => { name => 'hostname' },
        "port:s"            => { name => 'port', },
        "proto:s"           => { name => 'proto' },
        "urlpath:s"         => { name => 'url_path', default => "/nginx_status" },
        "credentials"       => { name => 'credentials' },
        "basic"             => { name => 'basic' },
        "username:s"        => { name => 'username' },
        "password:s"        => { name => 'password' },
        "timeout:s"         => { name => 'timeout' },
    });
    foreach (@{$maps}) {
        $options{options}->add_options(arguments => {
                                                    'warning-' . $_->{counter} . ':s'    => { name => 'warning_' . $_->{counter} },
                                                    'critical-' . $_->{counter} . ':s'    => { name => 'critical_' . $_->{counter} },
                                                    });
    }
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach (@{$maps}) {
        if (($self->{perfdata}->threshold_validate(label => 'warning-' . $_->{counter}, value => $self->{option_results}->{'warning_' . $_->{counter}})) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong warning-" . $_->{counter} . " threshold '" . $self->{option_results}->{'warning_' . $_->{counter}} . "'.");
            $self->{output}->option_exit();
        }
        if (($self->{perfdata}->threshold_validate(label => 'critical-' . $_->{counter}, value => $self->{option_results}->{'critical_' . $_->{counter}})) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong critical-" . $_->{counter} . " threshold '" . $self->{option_results}->{'critical_' . $_->{counter}} . "'.");
            $self->{output}->option_exit();
        }
    }
    
    $self->{statefile_value}->check_options(%options);
    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;

    my $webcontent = $self->{http}->request();
    my ($buffer_creation, $exit) = (0, 0);
    my $new_datas = {};
    my $old_datas = {};
    
    $self->{statefile_value}->read(statefile => 'nginx_' . $self->{option_results}->{hostname}  . '_' . $self->{http}->get_port() . '_' . $self->{mode});
    $old_datas->{timestamp} = $self->{statefile_value}->get(name => 'timestamp');
    $new_datas->{timestamp} = time();
    foreach (@{$maps}) {
        if ($webcontent !~ /$_->{match}/msi) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => "Cannot find " . $_->{counter} . " information.");
            next;
        }

        $new_datas->{$_->{counter}} = $1;
        my $tmp_value = $self->{statefile_value}->get(name => $_->{counter});
        if (!defined($tmp_value)) {
            $buffer_creation = 1;
            next;
        }
        if ($new_datas->{$_->{counter}} < $tmp_value) {
            $buffer_creation = 1;
            next;
        }
        
        $exit = 1;
        $old_datas->{$_->{counter}} = $tmp_value;
    }
    
    $self->{statefile_value}->write(data => $new_datas);
    if ($buffer_creation == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        if ($exit == 0) {
            $self->{output}->display();
            $self->{output}->exit();
        }
    }
    
    foreach (@{$maps}) {
        # In buffer creation.
        next if (!defined($old_datas->{$_->{counter}}));
        if ($new_datas->{$_->{counter}} - $old_datas->{$_->{counter}} == 0) {
            $self->{output}->output_add(severity => 'OK',
                                        short_msg => "Counter '" . $_->{counter} . "' not moved. Have to wait.");
            next;
        }
        
        my $delta_time = $new_datas->{timestamp} - $old_datas->{timestamp};
        $delta_time = 1 if ($delta_time <= 0);
        
        my $value = ($new_datas->{$_->{counter}} - $old_datas->{$_->{counter}}) / $delta_time;
        my $exit = $self->{perfdata}->threshold_check(value => $value, threshold => [ { label => 'critical-' . $_->{counter}, 'exit_litteral' => 'critical' }, { label => 'warning-' . $_->{counter}, 'exit_litteral' => 'warning' }]);
 
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf($_->{output}, $value));

        $self->{output}->perfdata_add(label => $_->{counter},
                                      value => sprintf('%.2f', $value),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $_->{counter}),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $_->{counter}),
                                      min => 0);
        
    }

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Nginx Request statistics: number of accepted connections per seconds, number of handled connections per seconds, number of requests per seconds.

=over 8

=item B<--hostname>

IP Addr/FQDN of the webserver host

=item B<--port>

Port used by Apache

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/nginx_status')

=item B<--credentials>

Specify this option if you access server-status page with authentication

=item B<--username>

Specify username for authentication (Mandatory if --credentials is specified)

=item B<--password>

Specify password for authentication (Mandatory if --credentials is specified)

=item B<--basic>

Specify this option if you access server-status page over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your webserver.

Specify this option if you access server-status page over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(Use with --credentials)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--warning-*>

Warning Threshold. Can be: 'accepts', 'handled', 'requests'.

=item B<--critical-*>

Critical Threshold. Can be: 'accepts', 'handled', 'requests'.

=back

=cut
