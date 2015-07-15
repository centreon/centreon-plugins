
package Paws::Kinesis::ListTagsForStreamOutput {
  use Moose;
  has HasMoreTags => (is => 'ro', isa => 'Bool', required => 1);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::Kinesis::Tag]', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::Kinesis::ListTagsForStreamOutput

=head1 ATTRIBUTES

=head2 B<REQUIRED> HasMoreTags => Bool

  

If set to C<true>, more tags are available. To request additional tags,
set C<ExclusiveStartTagKey> to the key of the last tag returned.









=head2 B<REQUIRED> Tags => ArrayRef[Paws::Kinesis::Tag]

  

A list of tags associated with C<StreamName>, starting with the first
tag after C<ExclusiveStartTagKey> and up to the specified C<Limit>.











=cut

1;