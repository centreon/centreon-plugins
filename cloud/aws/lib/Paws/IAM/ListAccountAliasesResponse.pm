
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

  

A flag that indicates whether there are more account aliases to list.
If your results were truncated, you can make a subsequent pagination
request using the C<Marker> request parameter to retrieve more account
aliases in the list.









=head2 Marker => Str

  

Use this only when paginating results, and only in a subsequent request
after you've received a response where the results are truncated. Set
it to the value of the C<Marker> element in the response you just
received.











=cut

