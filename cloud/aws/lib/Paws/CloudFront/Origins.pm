package Paws::CloudFront::Origins {
  use Moose;
  has Items => (is => 'ro', isa => 'ArrayRef[Paws::CloudFront::Origin]');
  has Quantity => (is => 'ro', isa => 'Int', required => 1);
}
1;
