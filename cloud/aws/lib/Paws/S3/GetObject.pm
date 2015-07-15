
package Paws::S3::GetObject {
  use Moose;
  has Bucket => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Bucket' , required => 1);
  has IfMatch => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'If-Match' );
  has IfModifiedSince => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'If-Modified-Since' );
  has IfNoneMatch => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'If-None-Match' );
  has IfUnmodifiedSince => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'If-Unmodified-Since' );
  has Key => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Key' , required => 1);
  has Range => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'Range' );
  has RequestPayer => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-request-payer' );
  has ResponseCacheControl => (is => 'ro', isa => 'Str');
  has ResponseContentDisposition => (is => 'ro', isa => 'Str');
  has ResponseContentEncoding => (is => 'ro', isa => 'Str');
  has ResponseContentLanguage => (is => 'ro', isa => 'Str');
  has ResponseContentType => (is => 'ro', isa => 'Str');
  has ResponseExpires => (is => 'ro', isa => 'Str');
  has SSECustomerAlgorithm => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-server-side-encryption-customer-algorithm' );
  has SSECustomerKey => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-server-side-encryption-customer-key' );
  has SSECustomerKeyMD5 => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-server-side-encryption-customer-key-MD5' );
  has VersionId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetObject');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/{Bucket}/{Key+}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::S3::GetObjectOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::S3::GetObjectOutput

=head1 ATTRIBUTES

=head2 B<REQUIRED> Bucket => Str

  
=head2 IfMatch => Str

  

Return the object only if its entity tag (ETag) is the same as the one
specified, otherwise return a 412 (precondition failed).









=head2 IfModifiedSince => Str

  

Return the object only if it has been modified since the specified
time, otherwise return a 304 (not modified).









=head2 IfNoneMatch => Str

  

Return the object only if its entity tag (ETag) is different from the
one specified, otherwise return a 304 (not modified).









=head2 IfUnmodifiedSince => Str

  

Return the object only if it has not been modified since the specified
time, otherwise return a 412 (precondition failed).









=head2 B<REQUIRED> Key => Str

  
=head2 Range => Str

  

Downloads the specified range bytes of an object. For more information
about the HTTP Range header, go to
http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html









=head2 RequestPayer => Str

  
=head2 ResponseCacheControl => Str

  

Sets the Cache-Control header of the response.









=head2 ResponseContentDisposition => Str

  

Sets the Content-Disposition header of the response









=head2 ResponseContentEncoding => Str

  

Sets the Content-Encoding header of the response.









=head2 ResponseContentLanguage => Str

  

Sets the Content-Language header of the response.









=head2 ResponseContentType => Str

  

Sets the Content-Type header of the response.









=head2 ResponseExpires => Str

  

Sets the Expires header of the response.









=head2 SSECustomerAlgorithm => Str

  

Specifies the algorithm to use to when encrypting the object (e.g.,
AES256, aws:kms).









=head2 SSECustomerKey => Str

  

Specifies the customer-provided encryption key for Amazon S3 to use in
encrypting data. This value is used to store the object and then it is
discarded; Amazon does not store the encryption key. The key must be
appropriate for use with the algorithm specified in the
x-amz-server-side-encryption-customer-algorithm header.









=head2 SSECustomerKeyMD5 => Str

  

Specifies the 128-bit MD5 digest of the encryption key according to RFC
1321. Amazon S3 uses this header for a message integrity check to
ensure the encryption key was transmitted without error.









=head2 VersionId => Str

  

VersionId used to reference a specific version of the object.











=cut

