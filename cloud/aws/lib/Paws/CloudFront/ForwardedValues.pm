package Paws::CloudFront::ForwardedValues {
  use Moose;
  has Cookies => (is => 'ro', isa => 'Paws::CloudFront::CookiePreference', required => 1);
  has Headers => (is => 'ro', isa => 'Paws::CloudFront::Headers');
  has QueryString => (is => 'ro', isa => 'Bool', required => 1);
}
1;
