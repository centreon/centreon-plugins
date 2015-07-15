package Paws::CloudFront::CachedMethods {
  use Moose;
  has Items => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has Quantity => (is => 'ro', isa => 'Int', required => 1);
}
1;
