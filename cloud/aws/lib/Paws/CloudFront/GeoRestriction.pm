package Paws::CloudFront::GeoRestriction {
  use Moose;
  has Items => (is => 'ro', isa => 'ArrayRef[Str]');
  has Quantity => (is => 'ro', isa => 'Int', required => 1);
  has RestrictionType => (is => 'ro', isa => 'Str', required => 1);
}
1;
