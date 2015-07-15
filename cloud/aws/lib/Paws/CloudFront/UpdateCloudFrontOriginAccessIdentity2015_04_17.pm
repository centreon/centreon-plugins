
package Paws::CloudFront::UpdateCloudFrontOriginAccessIdentity2015_04_17 {
  use Moose;
  has CloudFrontOriginAccessIdentityConfig => (is => 'ro', isa => 'Paws::CloudFront::CloudFrontOriginAccessIdentityConfig', required => 1);
  has Id => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Id' , required => 1);
  has IfMatch => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'If-Match' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateCloudFrontOriginAccessIdentity');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-04-17/origin-access-identity/cloudfront/{Id}/config');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'PUT');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudFront::UpdateCloudFrontOriginAccessIdentityResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFront::UpdateCloudFrontOriginAccessIdentityResult

=head1 ATTRIBUTES

=head2 B<REQUIRED> CloudFrontOriginAccessIdentityConfig => Paws::CloudFront::CloudFrontOriginAccessIdentityConfig

  

The identity's configuration information.









=head2 B<REQUIRED> Id => Str

  

The identity's id.









=head2 IfMatch => Str

  

The value of the ETag header you received when retrieving the
identity's configuration. For example: E2QWRUHAPOMQZL.











=cut

