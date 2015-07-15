
package Paws::EC2::CancelImportTaskResult {
  use Moose;
  has ImportTaskId => (is => 'ro', isa => 'Str', xmlname => 'importTaskId', traits => ['Unwrapped',]);
  has PreviousState => (is => 'ro', isa => 'Str', xmlname => 'previousState', traits => ['Unwrapped',]);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CancelImportTaskResult

=head1 ATTRIBUTES

=head2 ImportTaskId => Str

  

The ID of the task being canceled.









=head2 PreviousState => Str

  

The current state of the task being canceled.









=head2 State => Str

  

The current state of the task being canceled.











=cut

