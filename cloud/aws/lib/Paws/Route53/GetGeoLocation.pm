
package Paws::Route53::GetGeoLocation {
  use Moose;
  has ContinentCode => (is => 'ro', isa => 'Str');
  has CountryCode => (is => 'ro', isa => 'Str');
  has SubdivisionCode => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetGeoLocation');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/geolocation');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::GetGeoLocationResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::GetGeoLocationResponse

=head1 ATTRIBUTES

=head2 ContinentCode => Str

  

The code for a continent geo location. Note: only continent locations
have a continent code.

Valid values: C<AF> | C<AN> | C<AS> | C<EU> | C<OC> | C<NA> | C<SA>

Constraint: Specifying C<ContinentCode> with either C<CountryCode> or
C<SubdivisionCode> returns an InvalidInput error.









=head2 CountryCode => Str

  

The code for a country geo location. The default location uses '*' for
the country code and will match all locations that are not matched by a
geo location.

The default geo location uses a C<*> for the country code. All other
country codes follow the ISO 3166 two-character code.









=head2 SubdivisionCode => Str

  

The code for a country's subdivision (e.g., a province of Canada). A
subdivision code is only valid with the appropriate country code.

Constraint: Specifying C<SubdivisionCode> without C<CountryCode>
returns an InvalidInput error.











=cut

