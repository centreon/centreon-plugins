#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package cloud::aws::ec2::mode::listinstances;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{instances} = $options{custom}->ec2_list_resources(region => $self->{option_results}->{region});
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (@{$self->{instances}}) {
        next if ($_->{Type} !~ m/instance/);
        $self->{output}->output_add(long_msg => sprintf("[Name = %s][AvailabilityZone = %s][InstanceType = %s][State = %s][Tags = %s]",
            $_->{Name}, $_->{AvailabilityZone}, $_->{InstanceType}, $_->{State}, $_->{Tags}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List instances:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'availabilityzone', 'instancetype', 'state', 'tags']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (@{$self->{instances}}) {
        next if ($_->{Type} !~ m/instance/);
        $self->{output}->add_disco_entry(
            name => $_->{Name},
            availabilityzone => $_->{AvailabilityZone},
            instancetype => $_->{InstanceType},
            state => $_->{State},
            tags => $_->{Tags},
        );
    }
}

1;

__END__

=head1 MODE

List EC2 instances.

=over 8

=back

=cut
