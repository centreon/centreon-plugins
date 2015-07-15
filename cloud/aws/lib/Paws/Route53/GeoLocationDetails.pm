package Paws::Route53::GeoLocationDetails {
  use Moose;
  has ContinentCode => (is => 'ro', isa => 'Str');
  has ContinentName => (is => 'ro', isa => 'Str');
  has CountryCode => (is => 'ro', isa => 'Str');
  has CountryName => (is => 'ro', isa => 'Str');
  has SubdivisionCode => (is => 'ro', isa => 'Str');
  has SubdivisionName => (is => 'ro', isa => 'Str');
}
1;
