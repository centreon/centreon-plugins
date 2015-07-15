package Paws::CloudFront::Restrictions {
  use Moose;
  has GeoRestriction => (is => 'ro', isa => 'Paws::CloudFront::GeoRestriction', required => 1);
}
1;
