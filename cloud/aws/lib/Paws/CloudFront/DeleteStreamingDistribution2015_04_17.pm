
package Paws::CloudFront::DeleteStreamingDistribution2015_04_17 {
  use Moose;
  has Id => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Id' , required => 1);
  has IfMatch => (is => 'ro', isa => 'Str', traits => ['ParamInHeader'], header_name => 'If-Match' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteStreamingDistribution');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-04-17/streaming-distribution/{Id}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'DELETE');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFront::

=head1 ATTRIBUTES

=head2 B<REQUIRED> Id => Str

  

The distribution id.









=head2 IfMatch => Str

  

The value of the ETag header you received when you disabled the
streaming distribution. For example: E2QWRUHAPOMQZL.











=cut

