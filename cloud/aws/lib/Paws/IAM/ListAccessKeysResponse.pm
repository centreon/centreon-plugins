
package Paws::IAM::ListAccessKeysResponse {
  use Moose;
  has AccessKeyMetadata => (is => 'ro', isa => 'ArrayRef[Paws::IAM::AccessKeyMetadata]', required => 1);
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::ListAccessKeysResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> AccessKeyMetadata => ArrayRef[Paws::IAM::AccessKeyMetadata]

  

A list of access key metadata.









=head2 IsTruncated => Bool

  

A flag that indicates whether there are more items to return. If your
results were truncated, you can make a subsequent pagination request
using the C<Marker> request parameter to retrieve more items.









=head2 Marker => Str

  

When C<IsTruncated> is C<true>, this element is present and contains
the value to use for the C<Marker> parameter in a subsequent pagination
request.











=cut

