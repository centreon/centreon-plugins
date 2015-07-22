package Paws::CodePipeline::ActionRevision {
  use Moose;
  has created => (is => 'ro', isa => 'Str', required => 1);
  has revisionChangeId => (is => 'ro', isa => 'Str');
  has revisionId => (is => 'ro', isa => 'Str', required => 1);
}
1;
