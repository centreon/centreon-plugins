
package Paws::IAM::ListServerCertificatesResponse {
  use Moose;
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has Marker => (is => 'ro', isa => 'Str');
  has ServerCertificateMetadataList => (is => 'ro', isa => 'ArrayRef[Paws::IAM::ServerCertificateMetadata]', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::ListServerCertificatesResponse

=head1 ATTRIBUTES

=head2 IsTruncated => Bool

  

A flag that indicates whether there are more server certificates to
list. If your results were truncated, you can make a subsequent
pagination request using the C<Marker> request parameter to retrieve
more server certificates in the list.









=head2 Marker => Str

  

If C<IsTruncated> is C<true>, this element is present and contains the
value to use for the C<Marker> parameter in a subsequent pagination
request.









=head2 B<REQUIRED> ServerCertificateMetadataList => ArrayRef[Paws::IAM::ServerCertificateMetadata]

  

A list of server certificates.











=cut

