
package Paws::ElastiCache::RebootCacheCluster {
  use Moose;
  has CacheClusterId => (is => 'ro', isa => 'Str', required => 1);
  has CacheNodeIdsToReboot => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RebootCacheCluster');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::RebootCacheClusterResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'RebootCacheClusterResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::RebootCacheCluster - Arguments for method RebootCacheCluster on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method RebootCacheCluster on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method RebootCacheCluster.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RebootCacheCluster.

As an example:

  $service_obj->RebootCacheCluster(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CacheClusterId => Str

  

The cache cluster identifier. This parameter is stored as a lowercase
string.










=head2 B<REQUIRED> CacheNodeIdsToReboot => ArrayRef[Str]

  

A list of cache node IDs to reboot. A node ID is a numeric identifier
(0001, 0002, etc.). To reboot an entire cache cluster, specify all of
the cache node IDs.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RebootCacheCluster in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

