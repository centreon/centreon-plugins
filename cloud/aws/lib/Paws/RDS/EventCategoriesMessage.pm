
package Paws::RDS::EventCategoriesMessage {
  use Moose;
  has EventCategoriesMapList => (is => 'ro', isa => 'ArrayRef[Paws::RDS::EventCategoriesMap]', xmlname => 'EventCategoriesMap', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::EventCategoriesMessage

=head1 ATTRIBUTES

=head2 EventCategoriesMapList => ArrayRef[Paws::RDS::EventCategoriesMap]

  

A list of EventCategoriesMap data types.











=cut

