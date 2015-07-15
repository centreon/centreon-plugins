
package Paws::ElastiCache::DeleteCacheCluster {
  use Moose;
  has CacheClusterId => (is => 'ro', isa => 'Str', required => 1);
  has FinalSnapshotIdentifier => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteCacheCluster');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::DeleteCacheClusterResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DeleteCacheClusterResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::DeleteCacheCluster - Arguments for method DeleteCacheCluster on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteCacheCluster on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method DeleteCacheCluster.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteCacheCluster.

As an example:

  $service_obj->DeleteCacheCluster(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CacheClusterId => Str

  

The cache cluster identifier for the cluster to be deleted. This
parameter is not case sensitive.










=head2 FinalSnapshotIdentifier => Str

  

The user-supplied name of a final cache cluster snapshot. This is the
unique name that identifies the snapshot. ElastiCache creates the
snapshot, and then deletes the cache cluster immediately afterward.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteCacheCluster in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

