
package Paws::AutoScaling::DescribeAutoScalingNotificationTypesAnswer {
  use Moose;
  has AutoScalingNotificationTypes => (is => 'ro', isa => 'ArrayRef[Str]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DescribeAutoScalingNotificationTypesAnswer

=head1 ATTRIBUTES

=head2 AutoScalingNotificationTypes => ArrayRef[Str]

  

One or more of the following notification types:

=over

=item *

C<autoscaling:EC2_INSTANCE_LAUNCH>

=item *

C<autoscaling:EC2_INSTANCE_LAUNCH_ERROR>

=item *

C<autoscaling:EC2_INSTANCE_TERMINATE>

=item *

C<autoscaling:EC2_INSTANCE_TERMINATE_ERROR>

=item *

C<autoscaling:TEST_NOTIFICATION>

=back











=cut

