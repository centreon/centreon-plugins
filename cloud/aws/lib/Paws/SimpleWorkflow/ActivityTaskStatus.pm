
package Paws::SimpleWorkflow::ActivityTaskStatus {
  use Moose;
  has cancelRequested => (is => 'ro', isa => 'Bool', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::ActivityTaskStatus

=head1 ATTRIBUTES

=head2 B<REQUIRED> cancelRequested => Bool

  

Set to C<true> if cancellation of the task is requested.











=cut

1;