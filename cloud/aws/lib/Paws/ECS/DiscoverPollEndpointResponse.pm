
package Paws::ECS::DiscoverPollEndpointResponse {
  use Moose;
  has endpoint => (is => 'ro', isa => 'Str');
  has telemetryEndpoint => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::ECS::DiscoverPollEndpointResponse

=head1 ATTRIBUTES

=head2 endpoint => Str

  

The endpoint for the Amazon ECS agent to poll.









=head2 telemetryEndpoint => Str

  

The telemetry endpoint for the Amazon ECS agent.











=cut

1;