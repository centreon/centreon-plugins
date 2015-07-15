
package Paws::ElastiCache::CreateCacheSecurityGroup {
  use Moose;
  has CacheSecurityGroupName => (is => 'ro', isa => 'Str', required => 1);
  has Description => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateCacheSecurityGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::CreateCacheSecurityGroupResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateCacheSecurityGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::CreateCacheSecurityGroup - Arguments for method CreateCacheSecurityGroup on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateCacheSecurityGroup on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method CreateCacheSecurityGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateCacheSecurityGroup.

As an example:

  $service_obj->CreateCacheSecurityGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CacheSecurityGroupName => Str

  

A name for the cache security group. This value is stored as a
lowercase string.

Constraints: Must contain no more than 255 alphanumeric characters.
Cannot be the word "Default".

Example: C<mysecuritygroup>










=head2 B<REQUIRED> Description => Str

  

A description for the cache security group.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateCacheSecurityGroup in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

