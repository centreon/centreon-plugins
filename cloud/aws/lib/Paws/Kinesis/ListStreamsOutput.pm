
package Paws::Kinesis::ListStreamsOutput {
  use Moose;
  has HasMoreStreams => (is => 'ro', isa => 'Bool', required => 1);
  has StreamNames => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::Kinesis::ListStreamsOutput

=head1 ATTRIBUTES

=head2 B<REQUIRED> HasMoreStreams => Bool

  

If set to C<true>, there are more streams available to list.









=head2 B<REQUIRED> StreamNames => ArrayRef[Str]

  

The names of the streams that are associated with the AWS account
making the C<ListStreams> request.











=cut

1;