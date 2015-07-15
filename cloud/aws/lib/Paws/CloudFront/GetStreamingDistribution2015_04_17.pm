
package Paws::CloudFront::GetStreamingDistribution2015_04_17 {
  use Moose;
  has Id => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Id' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetStreamingDistribution');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-04-17/streaming-distribution/{Id}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudFront::GetStreamingDistributionResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFront::GetStreamingDistributionResult

=head1 ATTRIBUTES

=head2 B<REQUIRED> Id => Str

  

The streaming distribution's id.











=cut

