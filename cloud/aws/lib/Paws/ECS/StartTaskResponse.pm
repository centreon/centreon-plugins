
package Paws::ECS::StartTaskResponse {
  use Moose;
  has failures => (is => 'ro', isa => 'ArrayRef[Paws::ECS::Failure]');
  has tasks => (is => 'ro', isa => 'ArrayRef[Paws::ECS::Task]');

}

### main pod documentation begin ###

=head1 NAME

Paws::ECS::StartTaskResponse

=head1 ATTRIBUTES

=head2 failures => ArrayRef[Paws::ECS::Failure]

  

Any failed tasks from your C<StartTask> action are listed here.









=head2 tasks => ArrayRef[Paws::ECS::Task]

  

A full description of the tasks that were started. Each task that was
successfully placed on your container instances will be described here.











=cut

1;