
package Paws::SQS::CreateQueueResult {
  use Moose;
  has QueueUrl => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SQS::CreateQueueResult

=head1 ATTRIBUTES

=head2 QueueUrl => Str

  

The URL for the created Amazon SQS queue.











=cut

