
package Paws::RDS::EventsMessage {
  use Moose;
  has Events => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Event]', xmlname => 'Event', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::EventsMessage

=head1 ATTRIBUTES

=head2 Events => ArrayRef[Paws::RDS::Event]

  

A list of Event instances.









=head2 Marker => Str

  

An optional pagination token provided by a previous Events request. If
this parameter is specified, the response includes only records beyond
the marker, up to the value specified by C<MaxRecords> .











=cut

