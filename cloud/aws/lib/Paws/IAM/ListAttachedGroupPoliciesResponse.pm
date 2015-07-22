
package Paws::IAM::ListAttachedGroupPoliciesResponse {
  use Moose;
  has AttachedPolicies => (is => 'ro', isa => 'ArrayRef[Paws::IAM::AttachedPolicy]');
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::ListAttachedGroupPoliciesResponse

=head1 ATTRIBUTES

=head2 AttachedPolicies => ArrayRef[Paws::IAM::AttachedPolicy]

  

A list of the attached policies.









=head2 IsTruncated => Bool

  

A flag that indicates whether there are more items to return. If your
results were truncated, you can make a subsequent pagination request
using the C<Marker> request parameter to retrieve more items.









=head2 Marker => Str

  

When C<IsTruncated> is C<true>, this element is present and contains
the value to use for the C<Marker> parameter in a subsequent pagination
request.











=cut

