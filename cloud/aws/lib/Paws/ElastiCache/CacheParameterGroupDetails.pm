
package Paws::ElastiCache::CacheParameterGroupDetails {
  use Moose;
  has CacheNodeTypeSpecificParameters => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::CacheNodeTypeSpecificParameter]', xmlname => 'CacheNodeTypeSpecificParameter', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');
  has Parameters => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::Parameter]', xmlname => 'Parameter', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::CacheParameterGroupDetails

=head1 ATTRIBUTES

=head2 CacheNodeTypeSpecificParameters => ArrayRef[Paws::ElastiCache::CacheNodeTypeSpecificParameter]

  

A list of parameters specific to a particular cache node type. Each
element in the list contains detailed information about one parameter.









=head2 Marker => Str

  

Provides an identifier to allow retrieval of paginated results.









=head2 Parameters => ArrayRef[Paws::ElastiCache::Parameter]

  

A list of Parameter instances.











=cut

