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

package apps::mq::ibmmq::mqi::custom::api;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s' => { name => 'hostname' },
            'port:s'     => { name => 'port' },
            'channel:s'  => { name => 'channel' },
            'timeout:s'  => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CUSTOM MQI OPTIONS', once => 1);

    $self->{output} = $options{output};

    centreon::plugins::misc::mymodule_load(
        output => $self->{output},
        module => 'MQSeries::QueueManager',
        error_msg => "Cannot load module 'MQSeries::QueueManager'."
    );
    centreon::plugins::misc::mymodule_load(
        output => $self->{output},
        module => 'MQSeries::Command',
        error_msg => "Cannot load module 'MQSeries::Command'."
    );

    $self->{connected} = 0;
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{channel}  = (defined($self->{option_results}->{channel})) ? $self->{option_results}->{channel} : '';
    $self->{port}     = (defined($self->{option_results}->{port})) && $self->{option_results}->{port} =~ /(\d+)/ ? $1 : 1414;
    $self->{timeout}  = (defined($self->{option_results}->{timeout})) && $self->{option_results}->{timeout} =~ /(\d+)/ ? $1 : 30;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{channel} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --channel option.');
        $self->{output}->option_exit();
    }

    return 0;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{port};
}

sub get_qmgr_name {
    my ($self, %options) = @_;

    return $self->{qmgr_name};
}

sub my_logger {}

sub connect {
    my ($self, %options) = @_;

    return if ($self->{connected} == 1);

    my $reason;
    $self->{qmgr} = MQSeries::QueueManager->new(
        QueueManager => '',
        ConnectTimeout => $self->{timeout},
        Carp => \&my_logger,
        Reason => \$reason,
        ClientConn   => {
            'ChannelName'    => $self->{channel},
            'TransportType'  => 'TCP',
            'ConnectionName' => $self->{hostname} . '(' . $self->{port} . ')',
            'MaxMsgLength'   => 16 * 1024 * 1024
        }
    );
    if (!$self->{qmgr}) {
        $self->{output}->add_option_msg(short_msg => 'unable to connect to the queue manager: ' . MQSeries::MQReasonToText($reason));
        $self->{output}->option_exit();
    }

    $self->{mq_command} = MQSeries::Command->new(QueueManager => $self->{qmgr}, CommandVersion => eval('MQSeries::MQCFH_VERSION_3'));
    if (!$self->{mq_command}) {
        $self->{output}->add_option_msg(short_msg => 'unable to instantiate command object');
        $self->{output}->option_exit();
    }

    $self->{connected} = 1;

    my $results = $self->execute_command(command => 'InquireQueueManager');
    $self->{qmgr_name} = $results->[0]->{QMgrName};
}

sub execute_command {
    my ($self, %options) = @_;

    $self->connect();
    my @results;
    if ($options{command} eq 'InquireQueueManager') {
        @results = $self->{mq_command}->InquireQueueManager(%{$options{attrs}});
    } elsif ($options{command} eq 'InquireQueueManagerStatus') {
        @results = $self->{mq_command}->InquireQueueManagerStatus(%{$options{attrs}});
    } elsif ($options{command} eq 'InquireChannelStatus') {
        @results = $self->{mq_command}->InquireChannelStatus(%{$options{attrs}});
    } elsif ($options{command} eq 'InquireQueueStatus') {
        @results = $self->{mq_command}->InquireQueueStatus(%{$options{attrs}});
    } elsif ($options{command} eq 'InquireChannel') {
        @results = $self->{mq_command}->InquireChannel(%{$options{attrs}});
    }

    if (!@results) {
        $self->{output}->add_option_msg(short_msg => "method '$options{command}' issue: " . $self->{mq_command}->ReasonText());
        $self->{output}->option_exit();
    }

    return \@results;
}

1;

__END__

=head1 NAME

IBM MQ MQI

=head1 CUSTOM MQI OPTIONS

IBM MQ MQI

=over 8

=item B<--hostname>

Hostname or IP address.

=item B<--port>

Port used (Default: 1414)

=item B<--channel>

Channel name.

=item B<--timeout>

Set timeout in seconds (Default: 30).

=back

=head1 DESCRIPTION

B<custom>.

=cut
