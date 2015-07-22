
package Paws::IAM::GetAccountAuthorizationDetailsResponse {
  use Moose;
  has GroupDetailList => (is => 'ro', isa => 'ArrayRef[Paws::IAM::GroupDetail]');
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has Marker => (is => 'ro', isa => 'Str');
  has Policies => (is => 'ro', isa => 'ArrayRef[Paws::IAM::ManagedPolicyDetail]');
  has RoleDetailList => (is => 'ro', isa => 'ArrayRef[Paws::IAM::RoleDetail]');
  has UserDetailList => (is => 'ro', isa => 'ArrayRef[Paws::IAM::UserDetail]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::GetAccountAuthorizationDetailsResponse

=head1 ATTRIBUTES

=head2 GroupDetailList => ArrayRef[Paws::IAM::GroupDetail]

  

A list containing information about IAM groups.









=head2 IsTruncated => Bool

  

A flag that indicates whether there are more items to return. If your
results were truncated, you can make a subsequent pagination request
using the C<Marker> request parameter to retrieve more items.









=head2 Marker => Str

  

When C<IsTruncated> is C<true>, this element is present and contains
the value to use for the C<Marker> parameter in a subsequent pagination
request.









=head2 Policies => ArrayRef[Paws::IAM::ManagedPolicyDetail]

  

A list containing information about managed policies.









=head2 RoleDetailList => ArrayRef[Paws::IAM::RoleDetail]

  

A list containing information about IAM roles.









=head2 UserDetailList => ArrayRef[Paws::IAM::UserDetail]

  

A list containing information about IAM users.











=cut

