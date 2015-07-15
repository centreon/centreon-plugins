
package Paws::Route53::CreateHealthCheck {
  use Moose;
  has CallerReference => (is => 'ro', isa => 'Str', required => 1);
  has HealthCheckConfig => (is => 'ro', isa => 'Paws::Route53::HealthCheckConfig', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateHealthCheck');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/healthcheck');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::CreateHealthCheckResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::CreateHealthCheckResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> CallerReference => Str

  

A unique string that identifies the request and that allows failed
C<CreateHealthCheck> requests to be retried without the risk of
executing the operation twice. You must use a unique C<CallerReference>
string every time you create a health check. C<CallerReference> can be
any unique string; you might choose to use a string that identifies
your project.

Valid characters are any Unicode code points that are legal in an XML
1.0 document. The UTF-8 encoding of the value must be less than 128
bytes.









=head2 B<REQUIRED> HealthCheckConfig => Paws::Route53::HealthCheckConfig

  

A complex type that contains health check configuration.











=cut

