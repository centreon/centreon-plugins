
package Paws::S3::ListObjectVersionsOutput {
  use Moose;
  has CommonPrefixes => (is => 'ro', isa => 'ArrayRef[Paws::S3::CommonPrefix]');
  has DeleteMarkers => (is => 'ro', isa => 'ArrayRef[Paws::S3::DeleteMarkerEntry]');
  has Delimiter => (is => 'ro', isa => 'Str');
  has EncodingType => (is => 'ro', isa => 'Str');
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has KeyMarker => (is => 'ro', isa => 'Str');
  has MaxKeys => (is => 'ro', isa => 'Int');
  has Name => (is => 'ro', isa => 'Str');
  has NextKeyMarker => (is => 'ro', isa => 'Str');
  has NextVersionIdMarker => (is => 'ro', isa => 'Str');
  has Prefix => (is => 'ro', isa => 'Str');
  has VersionIdMarker => (is => 'ro', isa => 'Str');
  has Versions => (is => 'ro', isa => 'ArrayRef[Paws::S3::ObjectVersion]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::S3:: - Arguments for method  on Paws::S3

=head1 DESCRIPTION

This class represents the parameters used for calling the method  on the 
Amazon Simple Storage Service service. Use the attributes of this class
as arguments to method .

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to .

As an example:

  $service_obj->(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CommonPrefixes => ArrayRef[Paws::S3::CommonPrefix]

  

=head2 DeleteMarkers => ArrayRef[Paws::S3::DeleteMarkerEntry]

  

=head2 Delimiter => Str

  

=head2 EncodingType => Str

  

Encoding type used by Amazon S3 to encode object keys in the response.










=head2 IsTruncated => Bool

  

A flag that indicates whether or not Amazon S3 returned all of the
results that satisfied the search criteria. If your results were
truncated, you can make a follow-up paginated request using the
NextKeyMarker and NextVersionIdMarker response parameters as a starting
place in another request to return the rest of the results.










=head2 KeyMarker => Str

  

Marks the last Key returned in a truncated response.










=head2 MaxKeys => Int

  

=head2 Name => Str

  

=head2 NextKeyMarker => Str

  

Use this value for the key marker request parameter in a subsequent
request.










=head2 NextVersionIdMarker => Str

  

Use this value for the next version id marker parameter in a subsequent
request.










=head2 Prefix => Str

  

=head2 VersionIdMarker => Str

  

=head2 Versions => ArrayRef[Paws::S3::ObjectVersion]

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method  in L<Paws::S3>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

