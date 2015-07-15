
package Paws::Route53::ListResourceRecordSetsResponse {
  use Moose;
  has IsTruncated => (is => 'ro', isa => 'Bool', required => 1);
  has MaxItems => (is => 'ro', isa => 'Str', required => 1);
  has NextRecordIdentifier => (is => 'ro', isa => 'Str');
  has NextRecordName => (is => 'ro', isa => 'Str');
  has NextRecordType => (is => 'ro', isa => 'Str');
  has ResourceRecordSets => (is => 'ro', isa => 'ArrayRef[Paws::Route53::ResourceRecordSet]', traits => ['Unwrapped'], xmlname => 'ResourceRecordSet', required => 1);

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

=head2 B<REQUIRED> IsTruncated => Bool

  

A flag that indicates whether there are more resource record sets to be
listed. If your results were truncated, you can make a follow-up
request for the next page of results by using the
ListResourceRecordSetsResponse$NextRecordName element.

Valid Values: C<true> | C<false>










=head2 B<REQUIRED> MaxItems => Str

  

The maximum number of records you requested. The maximum value of
C<MaxItems> is 100.










=head2 NextRecordIdentifier => Str

  

I<Weighted resource record sets only:> If results were truncated for a
given DNS name and type, the value of C<SetIdentifier> for the next
resource record set that has the current DNS name and type.










=head2 NextRecordName => Str

  

If the results were truncated, the name of the next record in the list.
This element is present only if
ListResourceRecordSetsResponse$IsTruncated is true.










=head2 NextRecordType => Str

  

If the results were truncated, the type of the next record in the list.
This element is present only if
ListResourceRecordSetsResponse$IsTruncated is true.










=head2 B<REQUIRED> ResourceRecordSets => ArrayRef[Paws::Route53::ResourceRecordSet]

  

A complex type that contains information about the resource record sets
that are returned by the request.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method  in L<Paws::Route53>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

