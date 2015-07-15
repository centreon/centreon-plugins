
package Paws::CloudHSM::DescribeLunaClientResponse {
  use Moose;
  has Certificate => (is => 'ro', isa => 'Str');
  has CertificateFingerprint => (is => 'ro', isa => 'Str');
  has ClientArn => (is => 'ro', isa => 'Str');
  has Label => (is => 'ro', isa => 'Str');
  has LastModifiedTimestamp => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudHSM::DescribeLunaClientResponse

=head1 ATTRIBUTES

=head2 Certificate => Str

  

The certificate installed on the HSMs used by this client.









=head2 CertificateFingerprint => Str

  

The certificate fingerprint.









=head2 ClientArn => Str

  

The ARN of the client.









=head2 Label => Str

  

The label of the client.









=head2 LastModifiedTimestamp => Str

  

The date and time the client was last modified.











=cut

1;