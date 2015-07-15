
package Paws::OpsWorks::DescribeLoadBasedAutoScalingResult {
  use Moose;
  has LoadBasedAutoScalingConfigurations => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::LoadBasedAutoScalingConfiguration]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeLoadBasedAutoScalingResult

=head1 ATTRIBUTES

=head2 LoadBasedAutoScalingConfigurations => ArrayRef[Paws::OpsWorks::LoadBasedAutoScalingConfiguration]

  

An array of C<LoadBasedAutoScalingConfiguration> objects that describe
each layer's configuration.











=cut

1;