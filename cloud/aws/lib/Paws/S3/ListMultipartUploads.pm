
package Paws::S3::ListMultipartUploads {
  use Moose;
  has Bucket => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Bucket' , required => 1);
  has Delimiter => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'delimiter' );
  has EncodingType => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'encoding-type' );
  has KeyMarker => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'key-marker' );
  has MaxUploads => (is => 'ro', isa => 'Int', traits => ['ParamInQuery'], query_name => 'max-uploads' );
  has Prefix => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'prefix' );
  has UploadIdMarker => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'upload-id-marker' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListMultipartUploads');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/{Bucket}?uploads');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::S3::ListMultipartUploadsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::S3::ListMultipartUploadsOutput

=head1 ATTRIBUTES

=head2 B<REQUIRED> Bucket => Str

  
=head2 Delimiter => Str

  

Character you use to group keys.









=head2 EncodingType => Str

  
=head2 KeyMarker => Str

  

Together with upload-id-marker, this parameter specifies the multipart
upload after which listing should begin.









=head2 MaxUploads => Int

  

Sets the maximum number of multipart uploads, from 1 to 1,000, to
return in the response body. 1,000 is the maximum number of uploads
that can be returned in a response.









=head2 Prefix => Str

  

Lists in-progress uploads only for those keys that begin with the
specified prefix.









=head2 UploadIdMarker => Str

  

Together with key-marker, specifies the multipart upload after which
listing should begin. If key-marker is not specified, the
upload-id-marker parameter is ignored.











=cut

