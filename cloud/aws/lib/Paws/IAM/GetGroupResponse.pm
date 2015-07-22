
package Paws::IAM::GetGroupResponse {
  use Moose;
  has Group => (is => 'ro', isa => 'Paws::IAM::Group', required => 1);
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has Marker => (is => 'ro', isa => 'Str');
  has Users => (is => 'ro', isa => 'ArrayRef[Paws::IAM::User]', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::GetGroupResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Group => Paws::IAM::Group

  

Information about the group.









=head2 IsTruncated => Bool

  

A flag that indicates whether there are more items to return. If your
results were truncated, you can make a subsequent pagination request
using the C<Marker> request parameter to retrieve more items.









=head2 Marker => Str

  

When C<IsTruncated> is C<true>, this element is present and contains
the value to use for the C<Marker> parameter in a subsequent pagination
request.









=head2 B<REQUIRED> Users => ArrayRef[Paws::IAM::User]

  

A list of users in the group.











=cut

