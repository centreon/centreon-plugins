
package Paws::ElastiCache::ModifyCacheParameterGroup {
  use Moose;
  has CacheParameterGroupName => (is => 'ro', isa => 'Str', required => 1);
  has ParameterNameValues => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::ParameterNameValue]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyCacheParameterGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::CacheParameterGroupNameMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ModifyCacheParameterGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::ModifyCacheParameterGroup - Arguments for method ModifyCacheParameterGroup on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyCacheParameterGroup on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method ModifyCacheParameterGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyCacheParameterGroup.

As an example:

  $service_obj->ModifyCacheParameterGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CacheParameterGroupName => Str

  

The name of the cache parameter group to modify.










=head2 B<REQUIRED> ParameterNameValues => ArrayRef[Paws::ElastiCache::ParameterNameValue]

  

An array of parameter names and values for the parameter update. You
must supply at least one parameter name and value; subsequent arguments
are optional. A maximum of 20 parameters may be modified per request.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyCacheParameterGroup in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

