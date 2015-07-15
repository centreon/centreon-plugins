package Paws::CloudFront::CacheBehaviors {
  use Moose;
  has Items => (is => 'ro', isa => 'ArrayRef[Paws::CloudFront::CacheBehavior]');
  has Quantity => (is => 'ro', isa => 'Int', required => 1);
}
1;
