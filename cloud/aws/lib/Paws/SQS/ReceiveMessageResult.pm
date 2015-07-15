
package Paws::SQS::ReceiveMessageResult {
  use Moose;
  has Messages => (is => 'ro', isa => 'ArrayRef[Paws::SQS::Message]', xmlname => 'Message', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SQS::ReceiveMessageResult

=head1 ATTRIBUTES

=head2 Messages => ArrayRef[Paws::SQS::Message]

  

A list of messages.











=cut

