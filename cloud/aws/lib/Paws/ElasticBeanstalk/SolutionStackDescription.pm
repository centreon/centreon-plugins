package Paws::ElasticBeanstalk::SolutionStackDescription {
  use Moose;
  has PermittedFileTypes => (is => 'ro', isa => 'ArrayRef[Str]');
  has SolutionStackName => (is => 'ro', isa => 'Str');
}
1;
