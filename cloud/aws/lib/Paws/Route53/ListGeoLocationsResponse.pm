
package Paws::Route53::ListGeoLocationsResponse {
  use Moose;
  has GeoLocationDetailsList => (is => 'ro', isa => 'ArrayRef[Paws::Route53::GeoLocationDetails]', traits => ['Unwrapped'], xmlname => 'GeoLocationDetails', required => 1);
  has IsTruncated => (is => 'ro', isa => 'Bool', required => 1);
  has MaxItems => (is => 'ro', isa => 'Str', required => 1);
  has NextContinentCode => (is => 'ro', isa => 'Str');
  has NextCountryCode => (is => 'ro', isa => 'Str');
  has NextSubdivisionCode => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53:: - Arguments for method  on Paws::Route53

=head1 DESCRIPTION

This class represents the parameters used for calling the method  on the 
Amazon Route 53 service. Use the attributes of this class
as arguments to method .

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to .

As an example:

  $service_obj->(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> GeoLocationDetailsList => ArrayRef[Paws::Route53::GeoLocationDetails]

  

A complex type that contains information about the geo locations that
are returned by the request.










=head2 B<REQUIRED> IsTruncated => Bool

  

A flag that indicates whether there are more geo locations to be
listed. If your results were truncated, you can make a follow-up
request for the next page of results by using the values included in
the ListGeoLocationsResponse$NextContinentCode,
ListGeoLocationsResponse$NextCountryCode and
ListGeoLocationsResponse$NextSubdivisionCode elements.

Valid Values: C<true> | C<false>










=head2 B<REQUIRED> MaxItems => Str

  

The maximum number of records you requested. The maximum value of
C<MaxItems> is 100.










=head2 NextContinentCode => Str

  

If the results were truncated, the continent code of the next geo
location in the list. This element is present only if
ListGeoLocationsResponse$IsTruncated is true and the next geo location
to list is a continent location.










=head2 NextCountryCode => Str

  

If the results were truncated, the country code of the next geo
location in the list. This element is present only if
ListGeoLocationsResponse$IsTruncated is true and the next geo location
to list is not a continent location.










=head2 NextSubdivisionCode => Str

  

If the results were truncated, the subdivision code of the next geo
location in the list. This element is present only if
ListGeoLocationsResponse$IsTruncated is true and the next geo location
has a subdivision.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method  in L<Paws::Route53>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

