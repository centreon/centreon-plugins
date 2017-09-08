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

package apps::java::awa::jmx::mode::agents;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

use POSIX qw(strftime);
use Time::Local;
use Data::Dumper;

my $debug = 0;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(
        arguments => {
            "max-lastcheck:s" => { name => 'max_lastcheck', default => 200 },
            "agent-name:s"    => {
                name    => 'agent_name',
                default => 'NAME',
            },
        }
    );

    return $self;
}

sub epoch_time {
    my ($self, $date) = @_;

    my ($year, $month, $day, $hour, $min, $sec) = split /\W+/, $date;
    my $time = timelocal($sec, $min, $hour, $day, $month - 1, $year);

    return $time;
}

sub disco_format {
    my ($self, %options) = @_;

    my $attributs = [ 'name', 'side', 'type' ];
    $self->{output}->add_disco_format(elements => $attributs);

    return;
}

sub disco_show {
    my ($self, %options) = @_;

    print Data::Dumper->Dump([ \%options ], [qw(*options)]) if $debug;

    $self->manage_selection(%options);

    return;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{'disco_show'} = $options{'custom'}{'output'}{'option_results'}{'disco_show'};

    print Data::Dumper->Dump([ \%options ], [qw(*options)]) if $debug;

    $self->{request} = [
        {   mbean      => 'Automic:name=*,type=*,side=Agents',
            attributes => [
                { name => 'Active' },
                { name => 'Name' },
                { name => 'IpAddress' },
                { name => 'LastCheck' },
                { name => 'NetArea' },
            ]
        },
    ];

    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);

    my $app;
    foreach my $mbean (keys %{$result}) {
        $mbean =~ /Automic:name=(.*?),side=(.*),type=(.*)/;
        my $app  = defined($1) ? $1 : 'global';
        my $side = defined($2) ? $2 : 'global';
        my $type = defined($3) ? $3 : 'global';

        if ($options{'disco_show'}) {

            $self->{'app'}->{$app} = {
                'display'     => $app,
                'mbean_infos' => {
                    'side' => $side,
                    'type' => $type,
                },
            };
            next;
        }

        if (   (defined($self->{'option_results'}{'agent_name'}))
            && ($self->{'option_results'}{'agent_name'} ne '')
            && ($app !~ /$self->{'option_results'}{'agent_name'}/)
            && (!defined($options{'disco_show'})))
        {
            next;
        }

        $self->{'app'}->{$app} = {
            'display'     => $app,
            'Active'      => $result->{$mbean}->{'Active'},
            'Name'        => $result->{$mbean}->{'Name'},
            'LastCheck'   => $result->{$mbean}->{'LastCheck'},
            'NetArea'     => $result->{$mbean}->{'NetArea'},
            'mbean_infos' => {
                'side' => $side,
                'type' => $type,
            },
        };
    }

    if (defined($options{'disco_show'})) {

        foreach my $key (keys %{ $self->{'app'} }) {
            $self->{output}->add_disco_entry(
                'name' => $key,
                'type' => $self->{'app'}->{$key}->{'mbean_infos'}->{'type'},
                'side' => $self->{'app'}->{$key}->{'mbean_infos'}->{'side'},
            );
        }
        return;
    }

    print Data::Dumper->Dump([ $self->{'app'} ], [qw(*app)]) if $debug;

    my $expected_name = undef;

    if (   (defined($self->{'option_results'}{'agent_name'}))
        && ($self->{'option_results'}{'agent_name'} ne ''))
    {
        $expected_name = $self->{'option_results'}{'agent_name'};
    }

    # start algo
    my ($extented_status_information, $status_information, $severity,);

    if (scalar(keys %{ $self->{app} }) <= 0) {

        $status_information = "Agent ($expected_name) No found\n";
        $severity           = 'CRITICAL';
        $self->{output}->output_add(
            severity  => $severity,
            short_msg => $status_information,
            long_msg  => $extented_status_information,
        );
        $self->{output}->display();
        $self->{output}->exit();

        return;
    }

    my $v = JMX::Jmx4Perl::Util->dump_value($self->{'app'}->{$expected_name}->{'Active'},
        { format => 'DATA' });
    $v =~ s/^\s*//;
    $v =~ s/'//g;
    $v =~ s/\[//;
    $v =~ s/\]//;
    chomp($v);

    my $hash = {
        'max_lastcheck' => $self->{'option_results'}{'max_lastcheck'},
        'delta'         => $self->epoch_time(strftime "%Y-%m-%d %H:%M:%S", localtime)
            - $self->epoch_time($self->{'app'}->{$expected_name}->{'LastCheck'}),
        'NetArea' => $self->{'app'}->{$expected_name}->{'NetArea'},
        'Active'  => $v,
        'Name'    => $self->{'app'}->{$expected_name}->{'Name'},
        'display' => $self->{'app'}->{$expected_name}->{'display'},
        'type'    => $self->{'app'}->{$expected_name}->{'mbean_infos'}->{'type'},
        'side'    => $self->{'app'}->{$expected_name}->{'mbean_infos'}->{'side'},
    };

    print Data::Dumper->Dump([$hash], [qw(*hash)]) if $debug;

    if (    ($hash->{'delta'} < $hash->{'max_lastcheck'})
        and ($v eq 'true'))
    {
        $status_information
            = "Lastcheck ($hash->{'delta'}s) is fewer than $hash->{'max_lastcheck'} seconds.";
        $status_information .= " Agent is OK.\n";
        $severity = 'OK';
    }
    elsif ( ($hash->{'delta'} < $hash->{'max_lastcheck'})
        and ($hash->{'Active'} eq 'false'))
    {
        $status_information
            = "Lastcheck ($hash->{'delta'}s) is fewer than $hash->{'max_lastcheck'} seconds.";
        $status_information .= " Agent is not active.\n";
        $extented_status_information = "Server : $hash->{'IpAddress'}\n";
        $extented_status_information .= "Agent : $hash->{'Name'}\n";
        $extented_status_information .= "Env : $hash->{'NetArea'}\n";
        $severity = 'CRITICAL';
    }
    elsif ( ($hash->{'delta'} >= $hash->{'max_lastcheck'})
        and ($hash->{'Active'} eq 'true'))
    {
        $status_information
            = "Lastcheck ($hash->{'delta'}s) is greater than $hash->{'max_lastcheck'} seconds.";
        $status_information .= " Agent is OK.\n";
        $severity = 'CRITICAL';
    }
    elsif ( ($hash->{'delta'} >= $hash->{'max_lastcheck'})
        and ($hash->{'Active'} eq 'false'))
    {
        $status_information
            = "Lastcheck ($hash->{'delta'}s) is greater than $hash->{'max_lastcheck'} seconds.";
        $status_information .= " Agent is not active.\n";
        $extented_status_information = "Server : $hash->{'IpAddress'}\n";
        $extented_status_information .= "Agent : $hash->{'Name'}\n";
        $extented_status_information .= "Env : $hash->{'NetArea'}\n";
        $severity = 'CRITICAL';
    }
    else {
        $status_information = "Case not implemented";
        $severity           = 'CRITICAL';
    }

    $self->{output}->output_add(
        severity  => $severity,
        short_msg => $status_information,
        long_msg  => $extented_status_information,
    );
    $self->{output}->display();
    $self->{output}->exit();

    return;
}

1;

__END__

=head1 MODE
    
Agent Monitoring.

=over 8

=item B<--agent-name>

Name of agent (Default: 'NAME').

=item B<--max-lastcheck>

Maximum last check time (default: 200)

=back

=cut
