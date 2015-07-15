
package Paws::AutoScaling::EnterStandbyAnswer {
  use Moose;
  has Activities => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::Activity]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::EnterStandbyAnswer

=head1 ATTRIBUTES

=head2 Activities => ArrayRef[Paws::AutoScaling::Activity]

  

The activities related to moving instances into C<Standby> mode.











=cut

