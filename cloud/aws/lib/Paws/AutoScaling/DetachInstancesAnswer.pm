
package Paws::AutoScaling::DetachInstancesAnswer {
  use Moose;
  has Activities => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::Activity]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DetachInstancesAnswer

=head1 ATTRIBUTES

=head2 Activities => ArrayRef[Paws::AutoScaling::Activity]

  

The activities related to detaching the instances from the Auto Scaling
group.











=cut

