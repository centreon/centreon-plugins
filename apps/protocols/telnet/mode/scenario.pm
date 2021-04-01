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

package apps::protocols::telnet::mode::scenario;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use JSON;
use Net::Telnet;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "scenario:s"    => { name => 'scenario' },
        "warning:s"     => { name => 'warning' },
        "critical:s"    => { name => 'critical' },
        "hostname:s"    => { name => 'hostname' },
        "port:s"        => { name => 'port', default => 23 },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    # Example of a scenario file:
    # [
    #  {"cmd": "open", "options": { "Host": "10.0.0.1", "Port": "23", "Timeout": "30" } },
    #  {"cmd": "login", "options": { "Name": "admin", "Password": "pass", "Timeout": "5" } },
    #  {"cmd": "waitfor", "options": { "Match": "/string/", "Timeout": "5" } },
    #  {"cmd": "put", "options": { "String": "mystring", "Timeout": "5" } },
    #  {"cmd": "close" }
    #]
    if (!defined($self->{option_results}->{scenario})) { 
        $self->{output}->add_option_msg(short_msg => "Please specify a scenario file.");
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
}

sub read_scenario {
    my ($self, %options) = @_;
    
    my $content_scenario;
    if (-f $self->{option_results}->{scenario}) {
        $content_scenario = do {
            local $/ = undef;
            if (!open my $fh, "<", $self->{option_results}->{scenario}) {
                $self->{output}->add_option_msg(short_msg => "Could not open file $self->{option_results}->{scenario} : $!");
                $self->{output}->option_exit();
            }
            <$fh>;
        };
    } else {
        $content_scenario = $self->{option_results}->{scenario};
    }
    
    eval {
        $self->{json_scenario} = decode_json($content_scenario);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json scenario");
        $self->{output}->option_exit();
    }
}

sub execute_scenario {
    my ($self, %options) = @_;
    
    my $timing0 = [gettimeofday];
    my $session = new Net::Telnet();
    $session->errmode('return');
    
    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        if (!$session->open(Host => $self->{option_results}->{hostname}, Port => $self->{option_results}->{port}, Timeout => 30)) {
            $self->{output}->output_add(severity => 'critical',
                                        short_msg => sprintf("cannot open session: %s", $session->errmsg()));
            return ;
        }
    }
    
    my ($step_ok, $exit1) = (0, 'OK');
    my $step_total = scalar(@{$self->{json_scenario}});
    foreach my $cmd (@{$self->{json_scenario}}) {
        next if (!defined($cmd->{cmd}));
        if ($cmd->{cmd} !~ /^(open|login|waitfor|put|close)$/i) {
            $self->{output}->add_option_msg(short_msg => "command '$cmd->{cmd}' is not managed");
            $self->{output}->option_exit();
        }
        
        my $cmd_name = lc($cmd->{cmd});
        my $method = $session->can($cmd_name);
        if ($method) {            
            my $ret = $method->($session, defined($cmd->{options}) ? %{$cmd->{options}} : undef);
            if (!defined($ret)) {
                $self->{output}->output_add(long_msg => sprintf("errmsg: %s", $session->errmsg()));
                $exit1 = 'CRITICAL';
                last;
            }
        }
        
        $step_ok++;
    }
    
    my $timeelapsed = tv_interval($timing0, [gettimeofday]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                   threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("%d/%d steps (%.3fs)", $step_ok, $step_total, $timeelapsed));
                                
    $self->{output}->perfdata_add(label => "time", unit => 's',
                                  value => sprintf('%.3f', $timeelapsed),
                                  min => 0,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));
    $self->{output}->perfdata_add(label => "steps",
                                  value => $step_ok,
                                  min => 0,
                                  max => $step_total);
}

sub run {
    my ($self, %options) = @_;

    $self->read_scenario();
    $self->execute_scenario();

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check telnet scenario execution

=over 8

=item B<--scenario>

Scenario used (Required).
Can be a file or json content.

=item B<--timeout>

Set global execution timeout (Default: 50)

=item B<--hostname>

Set telnet hostname.
Could be used if you want to use the same scenario for X hosts.

=item B<--port>

Set telnet port.
Could be used if you want to use the same scenario for X hosts.

=item B<--warning>

Threshold warning in seconds (Scenario execution time)

=item B<--critical>

Threshold critical in seconds (Scenario execution time)

=back

=cut
