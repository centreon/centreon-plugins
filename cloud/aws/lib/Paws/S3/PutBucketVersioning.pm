
package Paws::S3::PutBucketVersioning {
  use Moose;
  has Bucket => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Bucket' , required => 1);
  has ContentMD5 => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'Content-MD5' );
  has MFA => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'x-amz-mfa' );
  has VersioningConfiguration => (is => 'ro', isa => 'Paws::S3::VersioningConfiguration', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutBucketVersioning');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/{Bucket}?versioning');
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

  
=head2 MFA => Str

  

The concatenation of the authentication device's serial number, a
space, and the value that is displayed on your authentication device.









=head2 B<REQUIRED> VersioningConfiguration => Paws::S3::VersioningConfiguration

  


=cut

