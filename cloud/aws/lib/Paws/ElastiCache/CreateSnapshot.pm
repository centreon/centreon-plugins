
package Paws::ElastiCache::CreateSnapshot {
  use Moose;
  has CacheClusterId => (is => 'ro', isa => 'Str', required => 1);
  has SnapshotName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateSnapshot');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::CreateSnapshotResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateSnapshotResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::CreateSnapshot - Arguments for method CreateSnapshot on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateSnapshot on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method CreateSnapshot.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateSnapshot.

As an example:

  $service_obj->CreateSnapshot(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CacheClusterId => Str

  

The identifier of an existing cache cluster. The snapshot will be
created from this cache cluster.










=head2 B<REQUIRED> SnapshotName => Str

  

A name for the snapshot being created.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateSnapshot in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

