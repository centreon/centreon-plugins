
package Paws::S3::UploadPartCopy {
  use Moose;
  has Bucket => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Bucket' , required => 1);
  has CopySource => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-copy-source' , required => 1);
  has CopySourceIfMatch => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-copy-source-if-match' );
  has CopySourceIfModifiedSince => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-copy-source-if-modified-since' );
  has CopySourceIfNoneMatch => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-copy-source-if-none-match' );
  has CopySourceIfUnmodifiedSince => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-copy-source-if-unmodified-since' );
  has CopySourceRange => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-copy-source-range' );
  has CopySourceSSECustomerAlgorithm => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-copy-source-server-side-encryption-customer-algorithm' );
  has CopySourceSSECustomerKey => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-copy-source-server-side-encryption-customer-key' );
  has CopySourceSSECustomerKeyMD5 => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-copy-source-server-side-encryption-customer-key-MD5' );
  has Key => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Key' , required => 1);
  has PartNumber => (is => 'ro', isa => 'Int', required => 1);
  has RequestPayer => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-request-payer' );
  has SSECustomerAlgorithm => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-server-side-encryption-customer-algorithm' );
  has SSECustomerKey => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-server-side-encryption-customer-key' );
  has SSECustomerKeyMD5 => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-server-side-encryption-customer-key-MD5' );
  has UploadId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UploadPartCopy');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/{Bucket}/{Key+}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'PUT');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::S3::UploadPartCopyOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::S3::UploadPartCopyOutput

=head1 ATTRIBUTES

=head2 B<REQUIRED> Bucket => Str

  
=head2 B<REQUIRED> CopySource => Str

  

The name of the source bucket and key name of the source object,
separated by a slash (/). Must be URL-encoded.









=head2 CopySourceIfMatch => Str

  

Copies the object if its entity tag (ETag) matches the specified tag.









=head2 CopySourceIfModifiedSince => Str

  

Copies the object if it has been modified since the specified time.









=head2 CopySourceIfNoneMatch => Str

  

Copies the object if its entity tag (ETag) is different than the
specified ETag.









=head2 CopySourceIfUnmodifiedSince => Str

  

Copies the object if it hasn't been modified since the specified time.









=head2 CopySourceRange => Str

  

The range of bytes to copy from the source object. The range value must
use the form bytes=first-last, where the first and last are the
zero-based byte offsets to copy. For example, bytes=0-9 indicates that
you want to copy the first ten bytes of the source. You can copy a
range only if the source object is greater than 5 GB.









=head2 CopySourceSSECustomerAlgorithm => Str

  

Specifies the algorithm to use when decrypting the source object (e.g.,
AES256).









=head2 CopySourceSSECustomerKey => Str

  

Specifies the customer-provided encryption key for Amazon S3 to use to
decrypt the source object. The encryption key provided in this header
must be one that was used when the source object was created.









=head2 CopySourceSSECustomerKeyMD5 => Str

  

Specifies the 128-bit MD5 digest of the encryption key according to RFC
1321. Amazon S3 uses this header for a message integrity check to
ensure the encryption key was transmitted without error.









=head2 B<REQUIRED> Key => Str

  
=head2 B<REQUIRED> PartNumber => Int

  

Part number of part being copied.









=head2 RequestPayer => Str

  
=head2 SSECustomerAlgorithm => Str

  

Specifies the algorithm to use to when encrypting the object (e.g.,
AES256, aws:kms).









=head2 SSECustomerKey => Str

  

Specifies the customer-provided encryption key for Amazon S3 to use in
encrypting data. This value is used to store the object and then it is
discarded; Amazon does not store the encryption key. The key must be
appropriate for use with the algorithm specified in the
x-amz-server-side-encryption-customer-algorithm header. This must be
the same encryption key specified in the initiate multipart upload
request.









=head2 SSECustomerKeyMD5 => Str

  

Specifies the 128-bit MD5 digest of the encryption key according to RFC
1321. Amazon S3 uses this header for a message integrity check to
ensure the encryption key was transmitted without error.









=head2 B<REQUIRED> UploadId => Str

  

Upload ID identifying the multipart upload whose part is being copied.











=cut

