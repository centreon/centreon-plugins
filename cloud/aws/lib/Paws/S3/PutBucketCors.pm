
package Paws::S3::PutBucketCors {
  use Moose;
  has Bucket => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Bucket' , required => 1);
  has ContentMD5 => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'Content-MD5' );
  has CORSConfiguration => (is => 'ro', isa => 'Paws::S3::CORSConfiguration');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutBucketCors');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/{Bucket}?cors');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'PUT');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::S3::

=head1 ATTRIBUTES

=head2 B<REQUIRED> Bucket => Str

  
=head2 ContentMD5 => Str

  
=head2 CORSConfiguration => Paws::S3::CORSConfiguration

  


=cut

