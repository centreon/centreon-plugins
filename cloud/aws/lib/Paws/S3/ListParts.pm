
package Paws::S3::ListParts {
  use Moose;
  has Bucket => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Bucket' , required => 1);
  has Key => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Key' , required => 1);
  has MaxParts => (is => 'ro', isa => 'Int');
  has PartNumberMarker => (is => 'ro', isa => 'Int');
  has RequestPayer => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-request-payer' );
  has UploadId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListParts');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/{Bucket}/{Key+}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::S3::ListPartsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::S3::ListPartsOutput

=head1 ATTRIBUTES

=head2 B<REQUIRED> Bucket => Str

  
=head2 B<REQUIRED> Key => Str

  
=head2 MaxParts => Int

  

Sets the maximum number of parts to return.









=head2 PartNumberMarker => Int

  

Specifies the part after which listing should begin. Only parts with
higher part numbers will be listed.









=head2 RequestPayer => Str

  
=head2 B<REQUIRED> UploadId => Str

  

Upload ID identifying the multipart upload whose parts are being
listed.











=cut

