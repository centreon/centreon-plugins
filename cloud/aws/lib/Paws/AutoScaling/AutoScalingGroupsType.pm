
package Paws::AutoScaling::AutoScalingGroupsType {
  use Moose;
  has AutoScalingGroups => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::AutoScalingGroup]', required => 1);
  has NextToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::AutoScalingGroupsType

=head1 ATTRIBUTES

=head2 B<REQUIRED> AutoScalingGroups => ArrayRef[Paws::AutoScaling::AutoScalingGroup]

  

The groups.









=head2 NextToken => Str

  

The token to use when requesting the next set of items. If there are no
additional items to return, the string is empty.











=cut

