
package Paws::AutoScaling::AutoScalingInstancesType {
  use Moose;
  has AutoScalingInstances => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::AutoScalingInstanceDetails]');
  has NextToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::AutoScalingInstancesType

=head1 ATTRIBUTES

=head2 AutoScalingInstances => ArrayRef[Paws::AutoScaling::AutoScalingInstanceDetails]

  

The instances.









=head2 NextToken => Str

  

The token to use when requesting the next set of items. If there are no
additional items to return, the string is empty.











=cut

