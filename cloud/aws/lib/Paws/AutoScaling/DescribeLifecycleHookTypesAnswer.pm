
package Paws::AutoScaling::DescribeLifecycleHookTypesAnswer {
  use Moose;
  has LifecycleHookTypes => (is => 'ro', isa => 'ArrayRef[Str]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DescribeLifecycleHookTypesAnswer

=head1 ATTRIBUTES

=head2 LifecycleHookTypes => ArrayRef[Str]

  

One or more of the following notification types:

=over

=item *

C<autoscaling:EC2_INSTANCE_LAUNCHING>

=item *

C<autoscaling:EC2_INSTANCE_TERMINATING>

=back











=cut

