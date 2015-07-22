
package Paws::S3::UploadPart {
  use Moose;
  has Body => (is => 'ro', isa => 'Str', traits => ['ParamInBody']);
  has Bucket => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Bucket' , required => 1);
  has ContentLength => (is => 'ro', isa => 'Int', traits => ['ParamInHeader'], header_name => 'Content-Length' );
  has ContentMD5 => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'Content-MD5' );
  has Key => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Key' , required => 1);
  has PartNumber => (is => 'ro', isa => 'Int', traits => ['ParamInQuery'], query_name => 'partNumber' , required => 1);
  has RequestPayer => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-request-payer' );
  has SSECustomerAlgorithm => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-server-side-encryption-customer-algorithm' );
  has SSECustomerKey => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-server-side-encryption-customer-key' );
  has SSECustomerKeyMD5 => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-server-side-encryption-customer-key-MD5' );
  has UploadId => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'uploadId' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UploadPart');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/{Bucket}/{Key+}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'PUT');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::S3::UploadPartOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::S3::UploadPartOutput

=head1 ATTRIBUTES

=head2 Body => Str

  
=head2 B<REQUIRED> Bucket => Str

  
=head2 ContentLength => Int

  

Size of the body in bytes. This parameter is useful when the size of
the body cannot be determined automatically.









=head2 ContentMD5 => Str

  
=head2 B<REQUIRED> Key => Str

  
=head2 B<REQUIRED> PartNumber => Int

  

Part number of part being uploaded.









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

  

Upload ID identifying the multipart upload whose part is being
uploaded.











=cut

