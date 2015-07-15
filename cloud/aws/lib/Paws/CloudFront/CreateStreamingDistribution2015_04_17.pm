
package Paws::CloudFront::CreateStreamingDistribution2015_04_17 {
  use Moose;
  has StreamingDistributionConfig => (is => 'ro', isa => 'Paws::CloudFront::StreamingDistributionConfig', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateStreamingDistribution');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-04-17/streaming-distribution');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudFront::CreateStreamingDistributionResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFront::CreateStreamingDistributionResult

=head1 ATTRIBUTES

=head2 B<REQUIRED> StreamingDistributionConfig => Paws::CloudFront::StreamingDistributionConfig

  

The streaming distribution's configuration information.











=cut

