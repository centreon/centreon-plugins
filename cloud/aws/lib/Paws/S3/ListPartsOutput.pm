
package Paws::S3::ListPartsOutput {
  use Moose;
  has Bucket => (is => 'ro', isa => 'Str');
  has Initiator => (is => 'ro', isa => 'Paws::S3::Initiator');
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has Key => (is => 'ro', isa => 'Str');
  has MaxParts => (is => 'ro', isa => 'Int');
  has NextPartNumberMarker => (is => 'ro', isa => 'Int');
  has Owner => (is => 'ro', isa => 'Paws::S3::Owner');
  has PartNumberMarker => (is => 'ro', isa => 'Int');
  has Parts => (is => 'ro', isa => 'ArrayRef[Paws::S3::Part]');
  has RequestCharged => (is => 'ro', isa => 'Str');
  has StorageClass => (is => 'ro', isa => 'Str');
  has UploadId => (is => 'ro', isa => 'Str');

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

=head2 Bucket => Str

  

Name of the bucket to which the multipart upload was initiated.










=head2 Initiator => Paws::S3::Initiator

  

Identifies who initiated the multipart upload.










=head2 IsTruncated => Bool

  

Indicates whether the returned list of parts is truncated.










=head2 Key => Str

  

Object key for which the multipart upload was initiated.










=head2 MaxParts => Int

  

Maximum number of parts that were allowed in the response.










=head2 NextPartNumberMarker => Int

  

When a list is truncated, this element specifies the last part in the
list, as well as the value to use for the part-number-marker request
parameter in a subsequent request.










=head2 Owner => Paws::S3::Owner

  

=head2 PartNumberMarker => Int

  

Part number after which listing begins.










=head2 Parts => ArrayRef[Paws::S3::Part]

  

=head2 RequestCharged => Str

  

=head2 StorageClass => Str

  

The class of storage used to store the object.










=head2 UploadId => Str

  

Upload ID identifying the multipart upload whose parts are being
listed.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method  in L<Paws::S3>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

