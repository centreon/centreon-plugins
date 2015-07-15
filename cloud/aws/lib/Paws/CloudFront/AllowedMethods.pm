package Paws::CloudFront::AllowedMethods {
  use Moose;
  has CachedMethods => (is => 'ro', isa => 'Paws::CloudFront::CachedMethods');
  has Items => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has Quantity => (is => 'ro', isa => 'Int', required => 1);
}
1;
