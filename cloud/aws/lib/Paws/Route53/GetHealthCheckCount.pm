
package Paws::Route53::GetHealthCheckCount {
  use Moose;

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetHealthCheckCount');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/healthcheckcount');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::GetHealthCheckCountResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::GetHealthCheckCountResponse

=head1 ATTRIBUTES



=cut

