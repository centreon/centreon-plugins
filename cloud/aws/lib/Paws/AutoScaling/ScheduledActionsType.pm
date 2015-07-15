
package Paws::AutoScaling::ScheduledActionsType {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has ScheduledUpdateGroupActions => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::ScheduledUpdateGroupAction]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::ScheduledActionsType

=head1 ATTRIBUTES

=head2 NextToken => Str

  

The token to use when requesting the next set of items. If there are no
additional items to return, the string is empty.









=head2 ScheduledUpdateGroupActions => ArrayRef[Paws::AutoScaling::ScheduledUpdateGroupAction]

  

The scheduled actions.











=cut

