
package Paws::ElastiCache::EventsMessage {
  use Moose;
  has Events => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::Event]', xmlname => 'Event', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::EventsMessage

=head1 ATTRIBUTES

=head2 Events => ArrayRef[Paws::ElastiCache::Event]

  

A list of events. Each element in the list contains detailed
information about one event.









=head2 Marker => Str

  

Provides an identifier to allow retrieval of paginated results.











=cut

