
package Paws::DataPipeline::ReportTaskRunnerHeartbeatOutput {
  use Moose;
  has terminate => (is => 'ro', isa => 'Bool', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::ReportTaskRunnerHeartbeatOutput

=head1 ATTRIBUTES

=head2 B<REQUIRED> terminate => Bool

  

Indicates whether the calling task runner should terminate.











=cut

1;