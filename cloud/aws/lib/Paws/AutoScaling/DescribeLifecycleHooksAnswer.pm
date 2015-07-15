
package Paws::AutoScaling::DescribeLifecycleHooksAnswer {
  use Moose;
  has LifecycleHooks => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::LifecycleHook]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DescribeLifecycleHooksAnswer

=head1 ATTRIBUTES

=head2 LifecycleHooks => ArrayRef[Paws::AutoScaling::LifecycleHook]

  

The lifecycle hooks for the specified group.











=cut

