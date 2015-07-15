
package Paws::Route53::GetHealthCheck {
  use Moose;
  has HealthCheckId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'HealthCheckId' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetHealthCheck');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/healthcheck/{HealthCheckId}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::GetHealthCheckResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::GetHealthCheckResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> HealthCheckId => Str

  

The ID of the health check to retrieve.











=cut

