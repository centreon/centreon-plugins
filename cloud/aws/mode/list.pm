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
package cloud::aws::mode::list;

use base qw(centreon::plugins::mode);
use strict;
use warnings;
use centreon::plugins::misc;
use JSON;

my $AWSServices         = 'EC2,S3,RDS';
my @Disco_service_tab   = ('EC2', 'RDS');
my $EC2_instance_states = 'running,stopped';
my $awsapi;

sub new
{
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    $self->{version} = '0.1';
    $options{options}->add_options(
        arguments => {
            "service:s" => {name => 'service', default => $AWSServices},
            "exclude-service:s" => {name => 'exclude_service'},
            "ec2-state:s"=>{name=> 'ec2_state', default => $EC2_instance_states},
            "ec2-exclude-state:s" => {name => 'ec2_exclude_state'},
        }
    );
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub api_request {
    my ($self, %options) = @_;

    @{$self->{option_results}->{servicetab}} = split( /,/, $self->{option_results}->{service} );
    # exclusions
    if (defined($self->{option_results}->{exclude_service})) {
        my @excludetab = split /,/, $self->{option_results}->{exclude_service};
        my %array1 = map { $_ => 1 } @excludetab;
        @{$self->{option_results}->{servicetab}} = grep { not $array1{$_} } @{$self->{option_results}->{servicetab}};
    }

    foreach my $service (@{$self->{option_results}->{servicetab}}) {
        $self->{result}->{count}->{$service} = 0;
        if ($service eq 'EC2') {
            $self->EC2(%options);
        } elsif ($service eq 'S3') {
            $self->S3(%options);
        } elsif ($service eq 'RDS') {
            $self->RDS(%options);
        } else {
            $self->{output}->add_option_msg(short_msg => "Service $service doesn't exists" );
            $self->{output}->option_exit();
        }
    }
}

sub EC2
{
    my ($self, %options) = @_;
    my $apiRequest = {
        'command'    => 'ec2',
        'subcommand' => 'describe-instances',
    };

    # Building JSON
    my @ec2_statestab = split(/,/, $self->{option_results}->{ec2_state});
    # exclusions
    if (defined($self->{option_results}->{ec2_exclude_state})) {
        my @excludetab = split /,/, $self->{option_results}->{ec2_exclude_state};
        my %array1 = map { $_ => 1 } @excludetab;
        @ec2_statestab = grep { not $array1{$_} } @ec2_statestab;
    }
    $apiRequest->{json} = {
        'DryRun'  => JSON::false,
        'Filters' => [
            {
                'Name'   => 'instance-state-name',
                'Values' => [@ec2_statestab],
            }
        ],
    };

    # Requesting API
    $awsapi = $options{custom};
    $self->{command_return} = $awsapi->execReq($apiRequest);

    # Compute data
    foreach my $instance (@{$self->{command_return}->{Reservations}}) {
        foreach my $tags (@{$instance->{Instances}[0]->{Tags}}) {
            if ($tags->{Key} eq 'Name') {
                $instance->{Instances}[0]->{Name} = $tags->{Value};
            }
        }
        $self->{result}->{'EC2'}->{$instance->{Instances}[0]->{InstanceId}} =
          {
            State => $instance->{Instances}[0]->{State}->{Name},
            Name => $instance->{Instances}[0]->{Name}
          };

        $self->{result}->{count}->{'EC2'}++;
    }
}

sub S3
{
    my ($self,    %options) = @_;
    my (@buckets, @return)  = ();
    my $apiRequest = {
        'command'    => 's3',
        'subcommand' => 'ls',
        'output'     => 'text'
    };

    # Requesting API
    $awsapi = $options{custom};
    $self->{command_return} = $awsapi->execReq($apiRequest);

    # Exec command
    foreach my $line (@{$self->{command_return}}) {
        my ($date, $time, $name) = split / /, $line;
        my $creationdate = $date . " " . $time;
        push(@buckets, { Name => $name, CreationDate => $creationdate });
    }

    # Compute data
    foreach my $bucket (@buckets) {
        $self->{result}->{'S3'}->{$bucket->{Name}} =
            {'Creation date' => $bucket->{CreationDate}};
        $self->{result}->{count}->{'S3'}++;
    }
}

sub RDS
{
    my ($self, %options) = @_;
    my $apiRequest = {
        'command'    => 'rds',
        'subcommand' => 'describe-db-instances',
    };

    # Requesting API
    $awsapi = $options{custom};
    $self->{command_return} = $awsapi->execReq($apiRequest);

    # Compute data
    foreach my $dbinstance (@{$self->{command_return}->{DBInstances}}) {
        $self->{result}->{'RDS'}->{$dbinstance->{DBInstanceIdentifier}} = {
            State => $dbinstance->{DBInstanceStatus},
            Name  => $dbinstance->{DBInstanceIdentifier}
        };
        $self->{result}->{count}->{RDS}++;
    }
}

sub disco_format {
    my ($self, %options) = @_;

    my $names = [ 'name', 'id', 'state', 'service' ];
    $self->{output}->add_disco_format( elements => $names );
}

sub disco_show
{
    my ($self, %options) = @_;
    $self->api_request(%options);
    foreach my $service (@Disco_service_tab) {
        foreach my $device (keys %{$self->{result}->{$service}}) {
            $self->{output}->add_disco_entry(
                name    => $self->{result}->{$service}->{$device}->{Name},
                id      => $device,
                state   => $self->{result}->{$service}->{$device}->{State},
                service => $service,
            );
        }
    }
}

sub run
{
    my ($self, %options) = @_;
    $self->api_request(%options);

    # Send formated data to Centreon
    foreach my $service (@{$self->{option_results}->{servicetab}}) {
        $self->{output}->output_add(long_msg => sprintf("AWS service: %s", $service));
        foreach my $device (keys %{$self->{result}->{$service}}) {
            my $output = $device . " [";
            foreach my $value (sort(keys %{$self->{result}->{$service}->{$device}})) {
                $output = $output . $value . " = " . $self->{result}->{$service}->{$device}->{$value} . ", ";
            }
            $output =~ s/, $//;
            $output = $output . "]";
            $self->{output}->output_add(long_msg => $output);
        }
        $self->{output}->output_add(short_msg => sprintf("%s: %s", $service, $self->{result}->{count}->{$service}));
    }
    $self->{output}->display(
        nolabel               => 1,
        force_ignore_perfdata => 1,
        force_long_output     => 1
    );
    $self->{output}->exit();
}
1;
__END__

=head1 MODE

List your EC2, RDS instance and S3 buckets

=over 8

=item B<--service>

(optional) List one particular service.

=item B<--exclude-service>

(optional) Service to exclude from the scan.

=item B<--ec2-state>

(optional) State to request (default: 'running','stopped')

=item B<--ec2-exclude-state>

(optional) State to exclude from the scan.

=back

=cut
