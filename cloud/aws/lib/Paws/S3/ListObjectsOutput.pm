
package Paws::S3::ListObjectsOutput {
  use Moose;
  has CommonPrefixes => (is => 'ro', isa => 'ArrayRef[Paws::S3::CommonPrefix]');
  has Contents => (is => 'ro', isa => 'ArrayRef[Paws::S3::Object]');
  has Delimiter => (is => 'ro', isa => 'Str');
  has EncodingType => (is => 'ro', isa => 'Str');
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has Marker => (is => 'ro', isa => 'Str');
  has MaxKeys => (is => 'ro', isa => 'Int');
  has Name => (is => 'ro', isa => 'Str');
  has NextMarker => (is => 'ro', isa => 'Str');
  has Prefix => (is => 'ro', isa => 'Str');

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

  

=head2 Contents => ArrayRef[Paws::S3::Object]

  

=head2 Delimiter => Str

  

=head2 EncodingType => Str

  

Encoding type used by Amazon S3 to encode object keys in the response.










=head2 IsTruncated => Bool

  

A flag that indicates whether or not Amazon S3 returned all of the
results that satisfied the search criteria.










=head2 Marker => Str

  

=head2 MaxKeys => Int

  

=head2 Name => Str

  

=head2 NextMarker => Str

  

When response is truncated (the IsTruncated element value in the
response is true), you can use the key name in this field as marker in
the subsequent request to get next set of objects. Amazon S3 lists
objects in alphabetical order Note: This element is returned only if
you have delimiter request parameter specified. If response does not
include the NextMaker and it is truncated, you can use the value of the
last Key in the response as the marker in the subsequent request to get
the next set of object keys.










=head2 Prefix => Str

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method  in L<Paws::S3>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

