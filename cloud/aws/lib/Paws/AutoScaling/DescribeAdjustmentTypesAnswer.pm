
package Paws::AutoScaling::DescribeAdjustmentTypesAnswer {
  use Moose;
  has AdjustmentTypes => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::AdjustmentType]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DescribeAdjustmentTypesAnswer

=head1 ATTRIBUTES

=head2 AdjustmentTypes => ArrayRef[Paws::AutoScaling::AdjustmentType]

  

The policy adjustment types.











=cut

