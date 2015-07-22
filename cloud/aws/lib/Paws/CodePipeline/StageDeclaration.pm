package Paws::CodePipeline::StageDeclaration {
  use Moose;
  has actions => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::ActionDeclaration]', required => 1);
  has blockers => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::BlockerDeclaration]');
  has name => (is => 'ro', isa => 'Str', required => 1);
}
1;
