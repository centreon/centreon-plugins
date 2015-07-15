
package Paws::RedShift::HsmClientCertificateMessage {
  use Moose;
  has HsmClientCertificates => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::HsmClientCertificate]', xmlname => 'HsmClientCertificate', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::HsmClientCertificateMessage

=head1 ATTRIBUTES

=head2 HsmClientCertificates => ArrayRef[Paws::RedShift::HsmClientCertificate]

  

A list of the identifiers for one or more HSM client certificates used
by Amazon Redshift clusters to store and retrieve database encryption
keys in an HSM.









=head2 Marker => Str

  

A value that indicates the starting point for the next set of response
records in a subsequent request. If a value is returned in a response,
you can retrieve the next set of records by providing this returned
marker value in the C<Marker> parameter and retrying the command. If
the C<Marker> field is empty, all response records have been retrieved
for the request.











=cut

