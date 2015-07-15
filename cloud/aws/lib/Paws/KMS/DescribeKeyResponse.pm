
package Paws::KMS::DescribeKeyResponse {
  use Moose;
  has KeyMetadata => (is => 'ro', isa => 'Paws::KMS::KeyMetadata');

}

### main pod documentation begin ###

=head1 NAME

Paws::KMS::DescribeKeyResponse

=head1 ATTRIBUTES

=head2 KeyMetadata => Paws::KMS::KeyMetadata

  

Metadata associated with the key.











=cut

1;