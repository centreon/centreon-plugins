
package Paws::ElasticBeanstalk::ApplicationVersionDescriptionsMessage {
  use Moose;
  has ApplicationVersions => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::ApplicationVersionDescription]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::ApplicationVersionDescriptionsMessage

=head1 ATTRIBUTES

=head2 ApplicationVersions => ArrayRef[Paws::ElasticBeanstalk::ApplicationVersionDescription]

  

A list of ApplicationVersionDescription .











=cut

