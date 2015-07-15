
package Paws::IAM::ListSigningCertificatesResponse {
  use Moose;
  has Certificates => (is => 'ro', isa => 'ArrayRef[Paws::IAM::SigningCertificate]', required => 1);
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::ListSigningCertificatesResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Certificates => ArrayRef[Paws::IAM::SigningCertificate]

  

A list of the user's signing certificate information.









=head2 IsTruncated => Bool

  

A flag that indicates whether there are more certificate IDs to list.
If your results were truncated, you can make a subsequent pagination
request using the C<Marker> request parameter to retrieve more
certificates in the list.









=head2 Marker => Str

  

If C<IsTruncated> is C<true>, this element is present and contains the
value to use for the C<Marker> parameter in a subsequent pagination
request.











=cut

