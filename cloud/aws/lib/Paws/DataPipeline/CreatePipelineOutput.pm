
package Paws::DataPipeline::CreatePipelineOutput {
  use Moose;
  has pipelineId => (is => 'ro', isa => 'Str', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::CreatePipelineOutput

=head1 ATTRIBUTES

=head2 B<REQUIRED> pipelineId => Str

  

The ID that AWS Data Pipeline assigns the newly created pipeline. For
example, C<df-06372391ZG65EXAMPLE>.











=cut

1;