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

package apps::hddtemp::remote::mode::temperature;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use IO::Socket;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
            {
            "hostname:s"            => { name => 'hostname' },
            "port:s"                => { name => 'port', default => '7634' },
            "timeout:s"             => { name => 'timeout', default => '10' },
            "name:s"                => { name => 'name' },
            "warning:s"             => { name => 'warning' },
            "critical:s"            => { name => 'critical' },
            "regexp"                => { name => 'use_regexp' },
            "regexp-isensitive"     => { name => 'use_regexpi' },
            });

    $self->{result} = {};
    $self->{hostname} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
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

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oSocketConn = new IO::Socket::INET ( Proto      => 'tcp', 
                                             PeerAddr   => $self->{option_results}->{hostname},
                                             PeerPort   => $self->{option_results}->{port},
                                             Timeout    => $self->{option_results}->{timeout},
                                           );
    
    if (!defined($oSocketConn)) {
        $self->{output}->add_option_msg(short_msg => "Could not connect.");
        $self->{output}->option_exit();
    }
    
    #|/dev/sda|SD280813AS|35|C|#|/dev/sdb|ST2000CD005-1CH134|35|C|

    my $line;
    
    eval {
        local $SIG{ALRM} = sub { die "Timeout by signal ALARM\n"; };
        alarm(10);
        $line = <$oSocketConn>;
        alarm(0);
    };
    $oSocketConn->shutdown(2);
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot get informations.");
        $self->{output}->option_exit();
    }

    while ($line =~ /\|([^|]+)\|([^|]+)\|([^|]+)\|(C|F)\|/g) {
        my ($drive, $serial, $temperature, $unit) = ($1, $2, $3, $4);

        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) 
            && $drive !~ /$self->{option_results}->{name}/i);
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) 
            && $drive !~ /$self->{option_results}->{name}/);
        next if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi})
            && $drive ne $self->{option_results}->{name});

        $self->{result}->{$drive} = {serial => $serial, temperature => $temperature, unit => $unit};
    }

    if (scalar(keys %{$self->{result}}) <= 0) {
        if (defined($self->{option_results}->{name})) {
            $self->{output}->add_option_msg(short_msg => "No drives found for name '" . $self->{option_results}->{name} . "'.");
        } else {
            $self->{output}->add_option_msg(short_msg => "No drives found.");
        }
        $self->{output}->option_exit();
    }

}

sub run {
    my ($self, %options) = @_;
    
    $self->manage_selection();

    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All Harddrive Temperatures are ok.');
    };

    foreach my $name (sort(keys %{$self->{result}})) {
        my $exit = $self->{perfdata}->threshold_check(value => $self->{result}->{$name}->{temperature}, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

        $self->{output}->output_add(long_msg => sprintf("Harddrive '%s' Temperature : %s%s", 
                                       $name,
                                       $self->{result}->{$name}->{temperature},
                                       $self->{result}->{$name}->{unit}));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Harddrive '%s' Temperature : %s%s",
                                       $name,
                                       $self->{result}->{$name}->{temperature},
                                       $self->{result}->{$name}->{unit}));
        }

        my $extra_label = '';
        $extra_label = '_' . $name if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp}));
        $self->{output}->perfdata_add(label => 'temp' . $extra_label,
                                      unit => $self->{result}->{$name}->{unit},
                                      value => sprintf("%.2f", $self->{result}->{$name}->{temperature}),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
    };

    $self->{output}->display();
    $self->{output}->exit();
};

1;

__END__

=head1 MODE

Check HDDTEMP Temperature by Socket Connect

=over 8

=item B<--hostname>

IP Address or FQDN of the Server

=item B<--port>

Port used by Hddtemp (Default: 7634)

=item B<--timeout>

Set Timeout for Socketconnect

=item B<--warning>

Warning Threshold for Temperature

=item B<--critical>

Critical Threshold for Temperature

=item B<--name>

Set the Harddrive name (empty means 'check all Harddrives')

=item B<--regexp>

Allows to use regexp to filter Harddrive (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=back

=cut
