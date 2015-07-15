
package Paws::Config::GetResourceConfigHistoryResponse {
  use Moose;
  has configurationItems => (is => 'ro', isa => 'ArrayRef[Paws::Config::ConfigurationItem]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::Config::GetResourceConfigHistoryResponse

=head1 ATTRIBUTES

=head2 configurationItems => ArrayRef[Paws::Config::ConfigurationItem]

  

A list that contains the configuration history of one or more
resources.









=head2 nextToken => Str

  

A token used for pagination of results.











=cut

1;