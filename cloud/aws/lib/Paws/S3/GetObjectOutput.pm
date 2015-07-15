
package Paws::S3::GetObjectOutput {
  use Moose;
  has AcceptRanges => (is => 'ro', isa => 'Str');
  has Body => (is => 'ro', isa => 'Str');
  has CacheControl => (is => 'ro', isa => 'Str');
  has ContentDisposition => (is => 'ro', isa => 'Str');
  has ContentEncoding => (is => 'ro', isa => 'Str');
  has ContentLanguage => (is => 'ro', isa => 'Str');
  has ContentLength => (is => 'ro', isa => 'Int');
  has ContentType => (is => 'ro', isa => 'Str');
  has DeleteMarker => (is => 'ro', isa => 'Bool');
  has ETag => (is => 'ro', isa => 'Str');
  has Expiration => (is => 'ro', isa => 'Str');
  has Expires => (is => 'ro', isa => 'Str');
  has LastModified => (is => 'ro', isa => 'Str');
  has Metadata => (is => 'ro', isa => 'Paws::S3::Metadata');
  has MissingMeta => (is => 'ro', isa => 'Int');
  has ReplicationStatus => (is => 'ro', isa => 'Str');
  has RequestCharged => (is => 'ro', isa => 'Str');
  has Restore => (is => 'ro', isa => 'Str');
  has ServerSideEncryption => (is => 'ro', isa => 'Str');
  has SSECustomerAlgorithm => (is => 'ro', isa => 'Str');
  has SSECustomerKeyMD5 => (is => 'ro', isa => 'Str');
  has SSEKMSKeyId => (is => 'ro', isa => 'Str');
  has VersionId => (is => 'ro', isa => 'Str');
  has WebsiteRedirectLocation => (is => 'ro', isa => 'Str');

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

=head2 AcceptRanges => Str

  

=head2 Body => Str

  

Object data.










=head2 CacheControl => Str

  

Specifies caching behavior along the request/reply chain.










=head2 ContentDisposition => Str

  

Specifies presentational information for the object.










=head2 ContentEncoding => Str

  

Specifies what content encodings have been applied to the object and
thus what decoding mechanisms must be applied to obtain the media-type
referenced by the Content-Type header field.










=head2 ContentLanguage => Str

  

The language the content is in.










=head2 ContentLength => Int

  

Size of the body in bytes.










=head2 ContentType => Str

  

A standard MIME type describing the format of the object data.










=head2 DeleteMarker => Bool

  

Specifies whether the object retrieved was (true) or was not (false) a
Delete Marker. If false, this response header does not appear in the
response.










=head2 ETag => Str

  

An ETag is an opaque identifier assigned by a web server to a specific
version of a resource found at a URL










=head2 Expiration => Str

  

If the object expiration is configured (see PUT Bucket lifecycle), the
response includes this header. It includes the expiry-date and rule-id
key value pairs providing object expiration information. The value of
the rule-id is URL encoded.










=head2 Expires => Str

  

The date and time at which the object is no longer cacheable.










=head2 LastModified => Str

  

Last modified date of the object










=head2 Metadata => Paws::S3::Metadata

  

A map of metadata to store with the object in S3.










=head2 MissingMeta => Int

  

This is set to the number of metadata entries not returned in
x-amz-meta headers. This can happen if you create metadata using an API
like SOAP that supports more flexible metadata than the REST API. For
example, using SOAP, you can create metadata whose values are not legal
HTTP headers.










=head2 ReplicationStatus => Str

  

=head2 RequestCharged => Str

  

=head2 Restore => Str

  

Provides information about object restoration operation and expiration
time of the restored object copy.










=head2 ServerSideEncryption => Str

  

The Server-side encryption algorithm used when storing this object in
S3 (e.g., AES256, aws:kms).










=head2 SSECustomerAlgorithm => Str

  

If server-side encryption with a customer-provided encryption key was
requested, the response will include this header confirming the
encryption algorithm used.










=head2 SSECustomerKeyMD5 => Str

  

If server-side encryption with a customer-provided encryption key was
requested, the response will include this header to provide round trip
message integrity verification of the customer-provided encryption key.










=head2 SSEKMSKeyId => Str

  

If present, specifies the ID of the AWS Key Management Service (KMS)
master encryption key that was used for the object.










=head2 VersionId => Str

  

Version of the object.










=head2 WebsiteRedirectLocation => Str

  

If the bucket is configured as a website, redirects requests for this
object to another object in the same bucket or to an external URL.
Amazon S3 stores the value of this header in the object metadata.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method  in L<Paws::S3>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

