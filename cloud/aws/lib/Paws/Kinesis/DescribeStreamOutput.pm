
package Paws::Kinesis::DescribeStreamOutput {
  use Moose;
  has StreamDescription => (is => 'ro', isa => 'Paws::Kinesis::StreamDescription', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::Kinesis::DescribeStreamOutput

=head1 ATTRIBUTES

=head2 B<REQUIRED> StreamDescription => Paws::Kinesis::StreamDescription

  

The current status of the stream, the stream ARN, an array of shard
objects that comprise the stream, and states whether there are more
shards available.











=cut

1;