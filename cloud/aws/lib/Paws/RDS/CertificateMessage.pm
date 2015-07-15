
package Paws::RDS::CertificateMessage {
  use Moose;
  has Certificates => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Certificate]', xmlname => 'Certificate', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::CertificateMessage

=head1 ATTRIBUTES

=head2 Certificates => ArrayRef[Paws::RDS::Certificate]

  

The list of Certificate objects for the AWS account.









=head2 Marker => Str

  

An optional pagination token provided by a previous
DescribeCertificates request. If this parameter is specified, the
response includes only records beyond the marker, up to the value
specified by C<MaxRecords> .











=cut

