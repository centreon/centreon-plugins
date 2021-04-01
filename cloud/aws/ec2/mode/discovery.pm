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

package cloud::aws::ec2::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "prettify"      => { name => 'prettify' },
        "filter-type:s" => { name => 'filter_type' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my @disco_data;
    my $disco_stats;

    $disco_stats->{start_time} = time();

    my %asgs;

    my $instances = $options{custom}->discovery(
        service => 'ec2',
        command => 'describe-instances'
    );

    foreach my $reservation (@{$instances->{Reservations}}) {
        foreach my $instance (@{$reservation->{Instances}}) {
            next if (!defined($instance->{InstanceId}));            
            my %asg;
            $asg{type} = "asg";
            my %ec2;
            $ec2{type} = "ec2";
            $ec2{id} = $instance->{InstanceId};
            $ec2{state} = $instance->{State}->{Name};
            $ec2{key_name} = $instance->{KeyName};
            $ec2{private_ip} = $instance->{PrivateIpAddress};
            $ec2{private_dns_name} = $instance->{PrivateDnsName};
            $ec2{public_dns_name} = $instance->{PublicDnsName};
            $ec2{instance_type} = $instance->{InstanceType};
            $ec2{vpc_id} = $instance->{VpcId};
            foreach my $tag (@{$instance->{Tags}}) {
                if ($tag->{Key} eq "aws:autoscaling:groupName" && defined($tag->{Value})) {
                    $ec2{asg} = $tag->{Value};
                    next if (defined($asgs{$tag->{Value}}));
                    $asg{name} = $tag->{Value};
                    $asgs{$tag->{Value}} = 1;
                }
                if ($tag->{Key} eq "Name" && defined($tag->{Value})) {
                    $ec2{name} = $tag->{Value};
                }
                push @{$ec2{tags}}, { key => $tag->{Key}, value => $tag->{Value} };
            }
            push @disco_data, \%ec2 unless (defined($self->{option_results}->{filter_type})
                && $ec2{type} !~ /$self->{option_results}->{filter_type}/);
            push @disco_data, \%asg unless ((defined($self->{option_results}->{filter_type})
                && $asg{type} !~ /$self->{option_results}->{filter_type}/) || !defined($asg{name}) || $asg{name} eq '');
        }
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = @disco_data;
    $disco_stats->{results} = \@disco_data;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }
    
    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

EC2/ASG discovery.

=over 8

=item B<--filter-type>

Filter type.

=item B<--prettify>

Prettify JSON output.

=back

=cut
