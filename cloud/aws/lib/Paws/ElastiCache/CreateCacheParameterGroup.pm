
package Paws::ElastiCache::CreateCacheParameterGroup {
  use Moose;
  has CacheParameterGroupFamily => (is => 'ro', isa => 'Str', required => 1);
  has CacheParameterGroupName => (is => 'ro', isa => 'Str', required => 1);
  has Description => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateCacheParameterGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::CreateCacheParameterGroupResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateCacheParameterGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::CreateCacheParameterGroup - Arguments for method CreateCacheParameterGroup on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateCacheParameterGroup on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method CreateCacheParameterGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateCacheParameterGroup.

As an example:

  $service_obj->CreateCacheParameterGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CacheParameterGroupFamily => Str

  

The name of the cache parameter group family the cache parameter group
can be used with.

Valid values are: C<memcached1.4> | C<redis2.6> | C<redis2.8>










=head2 B<REQUIRED> CacheParameterGroupName => Str

  

A user-specified name for the cache parameter group.










=head2 B<REQUIRED> Description => Str

  

A user-specified description for the cache parameter group.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateCacheParameterGroup in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

