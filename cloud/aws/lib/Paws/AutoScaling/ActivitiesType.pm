
package Paws::AutoScaling::ActivitiesType {
  use Moose;
  has Activities => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::Activity]', required => 1);
  has NextToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::ActivitiesType

=head1 ATTRIBUTES

=head2 B<REQUIRED> Activities => ArrayRef[Paws::AutoScaling::Activity]

  

The scaling activities.









=head2 NextToken => Str

  

The token to use when requesting the next set of items. If there are no
additional items to return, the string is empty.











=cut

