
package Paws::IAM::ListEntitiesForPolicyResponse {
  use Moose;
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has Marker => (is => 'ro', isa => 'Str');
  has PolicyGroups => (is => 'ro', isa => 'ArrayRef[Paws::IAM::PolicyGroup]');
  has PolicyRoles => (is => 'ro', isa => 'ArrayRef[Paws::IAM::PolicyRole]');
  has PolicyUsers => (is => 'ro', isa => 'ArrayRef[Paws::IAM::PolicyUser]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::ListEntitiesForPolicyResponse

=head1 ATTRIBUTES

=head2 IsTruncated => Bool

  

A flag that indicates whether there are more entities to list. If your
results were truncated, you can make a subsequent pagination request
using the C<Marker> request parameter to retrieve more entities in the
list.









=head2 Marker => Str

  

If C<IsTruncated> is C<true>, this element is present and contains the
value to use for the C<Marker> parameter in a subsequent pagination
request.









=head2 PolicyGroups => ArrayRef[Paws::IAM::PolicyGroup]

  

A list of groups that the policy is attached to.









=head2 PolicyRoles => ArrayRef[Paws::IAM::PolicyRole]

  

A list of roles that the policy is attached to.









=head2 PolicyUsers => ArrayRef[Paws::IAM::PolicyUser]

  

A list of users that the policy is attached to.











=cut

