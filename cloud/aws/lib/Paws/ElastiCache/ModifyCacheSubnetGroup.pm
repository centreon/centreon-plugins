
package Paws::ElastiCache::ModifyCacheSubnetGroup {
  use Moose;
  has CacheSubnetGroupDescription => (is => 'ro', isa => 'Str');
  has CacheSubnetGroupName => (is => 'ro', isa => 'Str', required => 1);
  has SubnetIds => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyCacheSubnetGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::ModifyCacheSubnetGroupResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ModifyCacheSubnetGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::ModifyCacheSubnetGroup - Arguments for method ModifyCacheSubnetGroup on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyCacheSubnetGroup on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method ModifyCacheSubnetGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyCacheSubnetGroup.

As an example:

  $service_obj->ModifyCacheSubnetGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CacheSubnetGroupDescription => Str

  

A description for the cache subnet group.










=head2 B<REQUIRED> CacheSubnetGroupName => Str

  

The name for the cache subnet group. This value is stored as a
lowercase string.

Constraints: Must contain no more than 255 alphanumeric characters or
hyphens.

Example: C<mysubnetgroup>










=head2 SubnetIds => ArrayRef[Str]

  

The EC2 subnet IDs for the cache subnet group.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyCacheSubnetGroup in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

