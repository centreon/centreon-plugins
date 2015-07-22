
package Paws::CodePipeline::AcknowledgeJobOutput {
  use Moose;
  has status => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::AcknowledgeJobOutput

=head1 ATTRIBUTES

=head2 status => Str

  

Whether the job worker has received the specified job.











=cut

1;