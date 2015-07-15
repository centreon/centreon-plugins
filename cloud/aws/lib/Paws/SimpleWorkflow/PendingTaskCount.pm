
package Paws::SimpleWorkflow::PendingTaskCount {
  use Moose;
  has count => (is => 'ro', isa => 'Int', required => 1);
  has truncated => (is => 'ro', isa => 'Bool');

}

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::PendingTaskCount

=head1 ATTRIBUTES

=head2 B<REQUIRED> count => Int

  

The number of tasks in the task list.









=head2 truncated => Bool

  

If set to true, indicates that the actual count was more than the
maximum supported by this API and the count returned is the truncated
value.











=cut

1;