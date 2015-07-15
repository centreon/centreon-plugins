
package Paws::ELB::ConfigureHealthCheckOutput {
  use Moose;
  has HealthCheck => (is => 'ro', isa => 'Paws::ELB::HealthCheck');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::ConfigureHealthCheckOutput

=head1 ATTRIBUTES

=head2 HealthCheck => Paws::ELB::HealthCheck

  

The updated health check.











=cut

