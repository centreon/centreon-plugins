
package Paws::AutoScaling::PoliciesType {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has ScalingPolicies => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::ScalingPolicy]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::PoliciesType

=head1 ATTRIBUTES

=head2 NextToken => Str

  

The token to use when requesting the next set of items. If there are no
additional items to return, the string is empty.









=head2 ScalingPolicies => ArrayRef[Paws::AutoScaling::ScalingPolicy]

  

The scaling policies.











=cut

