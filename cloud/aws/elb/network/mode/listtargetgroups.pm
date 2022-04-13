#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package cloud::aws::elb::network::mode::listtargetgroups;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'elb-name:s'                   => { name => 'elb_name' }
    });

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{elb_name} = defined($self->{option_results}->{elb_name}) ? $self->{option_results}->{elb_name} : '';
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{target_groups} = $options{custom}->elb_list_targetgroup();
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    foreach my $target_group (@{$self->{target_groups}}) {
        $target_group->{elb_arn} =~ s/(.*)\:loadbalancer\///g;
        $target_group->{targetgp_arn} =~ s/(.*)\://g;

        if ($target_group->{elb_arn} eq $self->{elb_name}) {
            $self->{output}->output_add(long_msg => sprintf("[TargetGroup = %s][VpcId = %s][HealthCheckProtocol = %s]",
                                                            $target_group->{targetgp_arn},
                                                            $target_group->{vpc_id},
                                                            $target_group->{healthcheck_proto}
                                                            ));
        }
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'Target-groups list:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['TargetGroup', 'VpcId', 'HealthCheckProtocol']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    
    foreach my $target_group (@{$self->{target_groups}}) {
        $target_group->{elb_arn} =~ s/(.*)\:loadbalancer\///g;
        $target_group->{targetgp_arn} =~ s/(.*)\://g;

        if ($target_group->{elb_arn} eq $self->{elb_name}) {
            $self->{output}->add_disco_entry(
                TargetGroup =>  $target_group->{targetgp_arn},
                VpcId =>  $target_group->{vpc_id},
                HealthCheckProtocol => $target_group->{healthcheck_proto}
            );
        }
    };
}

1;

__END__

=head1 MODE

List AWS target groups.

=over 8

=back

=cut
