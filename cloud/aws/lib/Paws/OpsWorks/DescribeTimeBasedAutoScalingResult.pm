
package Paws::OpsWorks::DescribeTimeBasedAutoScalingResult {
  use Moose;
  has TimeBasedAutoScalingConfigurations => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::TimeBasedAutoScalingConfiguration]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeTimeBasedAutoScalingResult

=head1 ATTRIBUTES

=head2 TimeBasedAutoScalingConfigurations => ArrayRef[Paws::OpsWorks::TimeBasedAutoScalingConfiguration]

  

An array of C<TimeBasedAutoScalingConfiguration> objects that describe
the configuration for the specified instances.











=cut

1;