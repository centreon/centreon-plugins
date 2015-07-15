package Paws::CloudFront::CustomOriginConfig {
  use Moose;
  has HTTPPort => (is => 'ro', isa => 'Int', required => 1);
  has HTTPSPort => (is => 'ro', isa => 'Int', required => 1);
  has OriginProtocolPolicy => (is => 'ro', isa => 'Str', required => 1);
}
1;
