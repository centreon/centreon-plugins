package Paws::CodePipeline::BlockerDeclaration {
  use Moose;
  has name => (is => 'ro', isa => 'Str', required => 1);
  has type => (is => 'ro', isa => 'Str', required => 1);
}
1;
