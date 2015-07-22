
package Paws::IAM::ListAccountAliasesResponse {
  use Moose;
  has AccountAliases => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::ListAccountAliasesResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> AccountAliases => ArrayRef[Str]

  

A list of aliases associated with the account.









=head2 IsTruncated => Bool

  

A flag that indicates whether there are more items to return. If your
results were truncated, you can make a subsequent pagination request
using the C<Marker> request parameter to retrieve more items.









=head2 Marker => Str

  

When C<IsTruncated> is C<true>, this element is present and contains
the value to use for the C<Marker> parameter in a subsequent pagination
request.











=cut

