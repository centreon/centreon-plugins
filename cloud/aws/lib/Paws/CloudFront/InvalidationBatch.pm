package Paws::CloudFront::InvalidationBatch {
  use Moose;
  has CallerReference => (is => 'ro', isa => 'Str', required => 1);
  has Paths => (is => 'ro', isa => 'Paws::CloudFront::Paths', required => 1);
}
1;
