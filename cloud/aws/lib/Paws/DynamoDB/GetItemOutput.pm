
package Paws::DynamoDB::GetItemOutput {
  use Moose;
  has ConsumedCapacity => (is => 'ro', isa => 'Paws::DynamoDB::ConsumedCapacity');
  has Item => (is => 'ro', isa => 'Paws::DynamoDB::AttributeMap');

}

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDB::GetItemOutput

=head1 ATTRIBUTES

=head2 ConsumedCapacity => Paws::DynamoDB::ConsumedCapacity

  
=head2 Item => Paws::DynamoDB::AttributeMap

  

A map of attribute names to I<AttributeValue> objects, as specified by
I<AttributesToGet>.











=cut

1;