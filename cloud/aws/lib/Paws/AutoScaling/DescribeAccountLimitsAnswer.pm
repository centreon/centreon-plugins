
package Paws::AutoScaling::DescribeAccountLimitsAnswer {
  use Moose;
  has MaxNumberOfAutoScalingGroups => (is => 'ro', isa => 'Int');
  has MaxNumberOfLaunchConfigurations => (is => 'ro', isa => 'Int');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DescribeAccountLimitsAnswer

=head1 ATTRIBUTES

=head2 MaxNumberOfAutoScalingGroups => Int

  

The maximum number of groups allowed for your AWS account. The default
limit is 20 per region.









=head2 MaxNumberOfLaunchConfigurations => Int

  

The maximum number of launch configurations allowed for your AWS
account. The default limit is 100 per region.











=cut

