package Paws::CloudFront::KeyPairIds {
  use Moose;
  has Items => (is => 'ro', isa => 'ArrayRef[Str]');
  has Quantity => (is => 'ro', isa => 'Int', required => 1);
}
1;
