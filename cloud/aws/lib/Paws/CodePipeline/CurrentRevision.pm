package Paws::CodePipeline::CurrentRevision {
  use Moose;
  has changeIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has revision => (is => 'ro', isa => 'Str', required => 1);
}
1;
