
package Paws::Route53::ListGeoLocations {
  use Moose;
  has MaxItems => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'maxitems' );
  has StartContinentCode => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'startcontinentcode' );
  has StartCountryCode => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'startcountrycode' );
  has StartSubdivisionCode => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'startsubdivisioncode' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListGeoLocations');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/geolocations');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::ListGeoLocationsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::ListGeoLocationsResponse

=head1 ATTRIBUTES

=head2 MaxItems => Str

  

The maximum number of geo locations you want in the response body.









=head2 StartContinentCode => Str

  

The first continent code in the lexicographic ordering of geo locations
that you want the C<ListGeoLocations> request to list. For
non-continent geo locations, this should be null.

Valid values: C<AF> | C<AN> | C<AS> | C<EU> | C<OC> | C<NA> | C<SA>

Constraint: Specifying C<ContinentCode> with either C<CountryCode> or
C<SubdivisionCode> returns an InvalidInput error.









=head2 StartCountryCode => Str

  

The first country code in the lexicographic ordering of geo locations
that you want the C<ListGeoLocations> request to list.

The default geo location uses a C<*> for the country code. All other
country codes follow the ISO 3166 two-character code.









=head2 StartSubdivisionCode => Str

  

The first subdivision code in the lexicographic ordering of geo
locations that you want the C<ListGeoLocations> request to list.

Constraint: Specifying C<SubdivisionCode> without C<CountryCode>
returns an InvalidInput error.











=cut

