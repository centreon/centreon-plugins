
package Paws::Route53::ListHealthChecksResponse {
  use Moose;
  has HealthChecks => (is => 'ro', isa => 'ArrayRef[Paws::Route53::HealthCheck]', traits => ['Unwrapped'], xmlname => 'HealthCheck', required => 1);
  has IsTruncated => (is => 'ro', isa => 'Bool', required => 1);
  has Marker => (is => 'ro', isa => 'Str', required => 1);
  has MaxItems => (is => 'ro', isa => 'Str', required => 1);
  has NextMarker => (is => 'ro', isa => 'Str');

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

=head2 B<REQUIRED> HealthChecks => ArrayRef[Paws::Route53::HealthCheck]

  

A complex type that contains information about the health checks
associated with the current AWS account.










=head2 B<REQUIRED> IsTruncated => Bool

  

A flag indicating whether there are more health checks to be listed. If
your results were truncated, you can make a follow-up request for the
next page of results by using the C<Marker> element.

Valid Values: C<true> | C<false>










=head2 B<REQUIRED> Marker => Str

  

If the request returned more than one page of results, submit another
request and specify the value of C<NextMarker> from the last response
in the C<marker> parameter to get the next page of results.










=head2 B<REQUIRED> MaxItems => Str

  

The maximum number of health checks to be included in the response
body. If the number of health checks associated with this AWS account
exceeds C<MaxItems>, the value of ListHealthChecksResponse$IsTruncated
in the response is C<true>. Call C<ListHealthChecks> again and specify
the value of ListHealthChecksResponse$NextMarker in the
ListHostedZonesRequest$Marker element to get the next page of results.










=head2 NextMarker => Str

  

Indicates where to continue listing health checks. If
ListHealthChecksResponse$IsTruncated is C<true>, make another request
to C<ListHealthChecks> and include the value of the C<NextMarker>
element in the C<Marker> element to get the next page of results.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method  in L<Paws::Route53>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

