
package Paws::SQS::ListQueuesResult {
  use Moose;
  has QueueUrls => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'QueueUrl', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SQS::ListQueuesResult

=head1 ATTRIBUTES

=head2 QueueUrls => ArrayRef[Str]

  

A list of queue URLs, up to 1000 entries.











=cut

