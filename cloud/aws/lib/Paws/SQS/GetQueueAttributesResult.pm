
package Paws::SQS::GetQueueAttributesResult {
  use Moose;
  has Attributes => (is => 'ro', isa => 'Paws::SQS::QueueAttributeMap', xmlname => 'Attribute', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SQS::GetQueueAttributesResult

=head1 ATTRIBUTES

=head2 Attributes => Paws::SQS::QueueAttributeMap

  

A map of attributes to the respective values.











=cut

