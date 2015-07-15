
package Paws::AutoScaling::ExitStandbyAnswer {
  use Moose;
  has Activities => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::Activity]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::ExitStandbyAnswer

=head1 ATTRIBUTES

=head2 Activities => ArrayRef[Paws::AutoScaling::Activity]

  

The activities related to moving instances out of C<Standby> mode.











=cut

