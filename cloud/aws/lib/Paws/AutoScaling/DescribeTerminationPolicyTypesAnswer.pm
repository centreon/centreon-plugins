
package Paws::AutoScaling::DescribeTerminationPolicyTypesAnswer {
  use Moose;
  has TerminationPolicyTypes => (is => 'ro', isa => 'ArrayRef[Str]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DescribeTerminationPolicyTypesAnswer

=head1 ATTRIBUTES

=head2 TerminationPolicyTypes => ArrayRef[Str]

  

The termination policies supported by Auto Scaling (C<OldestInstance>,
C<OldestLaunchConfiguration>, C<NewestInstance>,
C<ClosestToNextInstanceHour>, and C<Default>).











=cut

