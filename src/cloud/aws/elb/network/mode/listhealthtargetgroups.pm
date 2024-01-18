
#
# Copyright 2024 Centreon (http://www.centreon.com/)
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
package cloud::aws::elb::network::mode::listhealthtargetgroups;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'elb-name:s'    => { name => 'elb_name' }
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

    $self->{elb_name} = $self->{option_results}->{elb_name};
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{all_dimensions} = $options{custom}->cloudwatch_list_metrics(
        namespace => 'AWS/NetworkELB',
        metric    => 'HealthyHostCount'
    );
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    
    my @dimensions;
    
    foreach my $dimensions (@{$self->{all_dimensions}}) {
        my %health_dimensions;
        foreach my $dimension_name (@{$dimensions->{Dimensions}}) {
            $health_dimensions{availability_zone} = $dimension_name->{Value} if ($dimension_name->{Name} =~ m/AvailabilityZone/);
            $health_dimensions{elb_name} = $dimension_name->{Value} if ($dimension_name->{Name} =~ m/LoadBalancer/);
            $health_dimensions{target_group} = $dimension_name->{Value} if ($dimension_name->{Name} =~ m/TargetGroup/);
            $health_dimensions{target_group_display_name} = $health_dimensions{target_group};
            $health_dimensions{target_group_display_name} =~ s/(.*)targetgroup\///g; 
        }
        $health_dimensions{availability_zone} = defined($health_dimensions{availability_zone}) ? $health_dimensions{availability_zone} : '';
        next if ($health_dimensions{elb_name} ne $self->{elb_name});
        push @dimensions, \%health_dimensions;
    }

    foreach my $dimensions (@dimensions){
        $self->{output}->output_add(
            long_msg => sprintf("[target_group = %s][target_group_display_name = %s][elb = %s][availability_zone = %s]", 
            $dimensions->{target_group},
            $dimensions->{target_group_display_name},
            $dimensions->{elb_name},
            $dimensions->{availability_zone})
        );
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

    $self->{output}->add_disco_format(elements => ['target_group', 'target_group_display_name', 'elb', 'availability_zone']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    my @dimensions;
    
    foreach my $dimensions (@{$self->{all_dimensions}}) {
        my %health_dimensions;
        foreach my $dimension_name (@{$dimensions->{Dimensions}}) {
            $health_dimensions{availability_zone} = $dimension_name->{Value} if ($dimension_name->{Name} =~ m/AvailabilityZone/);
            $health_dimensions{elb_name} = $dimension_name->{Value} if ($dimension_name->{Name} =~ m/LoadBalancer/);
            $health_dimensions{target_group} = $dimension_name->{Value} if ($dimension_name->{Name} =~ m/TargetGroup/);
            $health_dimensions{target_group_display_name} = $health_dimensions{target_group};
            $health_dimensions{target_group_display_name} =~ s/(.*)targetgroup\///g; 
        }
        $health_dimensions{availability_zone} = defined($health_dimensions{availability_zone}) ? $health_dimensions{availability_zone} : '';
        next if ($health_dimensions{elb_name} ne $self->{elb_name});
        push @dimensions, \%health_dimensions;
    }

    foreach my $dimensions (@dimensions){
        $self->{output}->add_disco_entry(
            target_group => $dimensions->{target_group},
            target_group_display_name => $dimensions->{target_group_display_name},
            elb => $dimensions->{elb_name},
            availability_zone => $dimensions->{availability_zone},
        );
    }
}

1;

__END__

=head1 MODE

List AWS target groups for a given ELB with --elb-name parameter.

=over 8

=back

=cut
