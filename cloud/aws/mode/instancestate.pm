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

package cloud::aws::mode::instancestate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use Data::Dumper;
use JSON;

my %EC2_instance_states = (
    'pending'       => 'WARNING',
    'running'       => 'OK',
    'shutting-down' => 'CRITICAL',
    'terminated'    => 'CRITICAL',
    'stopping'      => 'CRITICAL',
    'stopped'       => 'CRITICAL'
);

my $apiRequest = {
    'command'    => 'ec2',
    'subcommand' => 'describe-instance-status',
};

sub new {
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new( package => __PACKAGE__, %options );
    bless $self, $class;

    $self->{version} = '0.1';

    $options{options}->add_options(
        arguments => {
            "state:s"                => { name => 'state', default => 'all' },
            "no-includeallinstances" => { name => 'includeallinstances' },
            "exclude:s"              => { name => 'exclude' },
            "instanceid:s"           => { name => 'instanceid' }
        }
    );
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my (@result, $awsapi);

    # Getting some parameters
    # includeallinstances
    if (defined($self->{option_results}->{includeallinstances})) {
        $self->{option_results}->{includeallinstances} = JSON::false;
    } else {
        $self->{option_results}->{includeallinstances} = JSON::true;
    }

    # states
    if ($self->{option_results}->{state} eq 'all') {
        @{$self->{option_results}->{statetab} } = keys %EC2_instance_states;
    } else {
        @{$self->{option_results}->{statetab}} = split /,/, $self->{option_results}->{state};
        foreach my $curstate (@{$self->{option_results}->{statetab}}) {
            if (!grep { /^$curstate$/ } keys(%EC2_instance_states)) {
                $self->{output}->add_option_msg(severity  => 'UNKNOWN', short_msg => "The state doesn't exist.");
                $self->{output}->option_exit();
            }
        }
    }

    # exclusions
    if (defined($self->{option_results}->{exclude})) {
        my @excludetab = split /,/, $self->{option_results}->{exclude};
        my %array1 = map { $_ => 1 } @excludetab;
        @{$self->{option_results}->{statetab}} = grep { not $array1{$_} } @{$self->{option_results}->{statetab}};
    }
    my $states = join(',',@{$self->{option_results}->{statetab}});
    
    # Getting data from AWS
    # Building JSON
    $apiRequest->{json} = {
        'DryRun'     => JSON::false,
        'IncludeAllInstances'    => $self->{option_results}->{includeallinstances},
        'Filters' => [
            {
                'Name'  => 'instance-state-name',
                'Values' => $self->{option_results}->{statetab},
            }],
    };
    # InstanceIds
    if (defined($self->{option_results}->{instanceid})) {
        my @InstanceIds = split(/,/, $self->{option_results}->{instanceid});
        @{$apiRequest->{json}{InstanceIds}} = @InstanceIds;
    }

    # Requesting API
    $awsapi = $options{custom};
    $self->{command_return} = $awsapi->execReq($apiRequest);
        
    # Compute data
    $self->{option_results}->{instancecount}->{total} = 0;
    foreach my $curstate (@{$self->{option_results}->{statetab}}) {
        $self->{option_results}->{instancecount}->{$curstate} = 0;
    }
    foreach my $l (@{$self->{command_return}->{InstanceStatuses}}) {
        $self->{result}->{instance}->{$l->{InstanceId}} = $l->{InstanceState}->{Name};

        # long output for each instance
        $self->{output}->output_add(long_msg => "'" . $l->{InstanceId} . "' [state = " . $l->{InstanceState}->{Name} . ']');

        foreach my $curstate (@{$self->{option_results}->{statetab}}) {
            if ($l->{InstanceState}->{Name} eq $curstate) {
                $self->{option_results}->{instancecount}->{$curstate}++;
            }
        }
        $self->{option_results}->{instancecount}->{total}++;
    }
}

sub run {
    my ( $self, %options ) = @_;

    my ( $msg, $exit_code );
    my $old_status = 'OK';

    $self->manage_selection(%options);

    # Send formated data to Centreon
    # Perf data
    $self->{output}->perfdata_add(
        label => 'total',
        value => $self->{option_results}->{instancecount}->{'total'},
    );

    foreach my $curstate (@{$self->{option_results}->{statetab}}) {
        $self->{output}->perfdata_add(
            label => $curstate,
            value => $self->{option_results}->{instancecount}->{$curstate},
        );

        # Most critical state
        if ($self->{option_results}->{instancecount}->{$curstate} != 0) {
            $exit_code = $EC2_instance_states{$curstate};
            $exit_code = $self->{output}->get_most_critical(status => [ $exit_code, $old_status ]);
            $old_status = $exit_code;
        }
    }

    # Output message
    $self->{output}->output_add(
        severity  => $exit_code,
        short_msg => sprintf("Total instances: %s", $self->{option_results}->{instancecount}->{total})
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Get the state of your EC2 instances (running, stopped, ...)

=over 8

=item B<--state>

(optional) Specific state to query.

=item B<--no-includeallinstances>

(optional) Includes the health status for running instances only.

=item B<--exclude>

(optional) State to exclude from the query.

=back

=cut
