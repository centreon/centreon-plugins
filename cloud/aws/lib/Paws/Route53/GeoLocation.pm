package Paws::Route53::GeoLocation {
  use Moose;
  has ContinentCode => (is => 'ro', isa => 'Str');
  has CountryCode => (is => 'ro', isa => 'Str');
  has SubdivisionCode => (is => 'ro', isa => 'Str');
}
1;
