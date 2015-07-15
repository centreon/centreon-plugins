
package Paws::S3::ListMultipartUploadsOutput {
  use Moose;
  has Bucket => (is => 'ro', isa => 'Str');
  has CommonPrefixes => (is => 'ro', isa => 'ArrayRef[Paws::S3::CommonPrefix]');
  has Delimiter => (is => 'ro', isa => 'Str');
  has EncodingType => (is => 'ro', isa => 'Str');
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has KeyMarker => (is => 'ro', isa => 'Str');
  has MaxUploads => (is => 'ro', isa => 'Int');
  has NextKeyMarker => (is => 'ro', isa => 'Str');
  has NextUploadIdMarker => (is => 'ro', isa => 'Str');
  has Prefix => (is => 'ro', isa => 'Str');
  has UploadIdMarker => (is => 'ro', isa => 'Str');
  has Uploads => (is => 'ro', isa => 'ArrayRef[Paws::S3::MultipartUpload]');

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










=head2 CommonPrefixes => ArrayRef[Paws::S3::CommonPrefix]

  

=head2 Delimiter => Str

  

=head2 EncodingType => Str

  

Encoding type used by Amazon S3 to encode object keys in the response.










=head2 IsTruncated => Bool

  

Indicates whether the returned list of multipart uploads is truncated.
A value of true indicates that the list was truncated. The list can be
truncated if the number of multipart uploads exceeds the limit allowed
or specified by max uploads.










=head2 KeyMarker => Str

  

The key at or after which the listing began.










=head2 MaxUploads => Int

  

Maximum number of multipart uploads that could have been included in
the response.










=head2 NextKeyMarker => Str

  

When a list is truncated, this element specifies the value that should
be used for the key-marker request parameter in a subsequent request.










=head2 NextUploadIdMarker => Str

  

When a list is truncated, this element specifies the value that should
be used for the upload-id-marker request parameter in a subsequent
request.










=head2 Prefix => Str

  

When a prefix is provided in the request, this field contains the
specified prefix. The result contains only keys starting with the
specified prefix.










=head2 UploadIdMarker => Str

  

Upload ID after which listing began.










=head2 Uploads => ArrayRef[Paws::S3::MultipartUpload]

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method  in L<Paws::S3>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

