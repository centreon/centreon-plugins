
package Paws::ElasticBeanstalk::ConfigurationOptionsDescription {
  use Moose;
  has Options => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionDescription]');
  has SolutionStackName => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::ConfigurationOptionsDescription

=head1 ATTRIBUTES

=head2 Options => ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionDescription]

  

A list of ConfigurationOptionDescription.









=head2 SolutionStackName => Str

  

The name of the solution stack these configuration options belong to.











=cut

