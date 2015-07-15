
package Paws::ElastiCache::ResetCacheParameterGroup {
  use Moose;
  has CacheParameterGroupName => (is => 'ro', isa => 'Str', required => 1);
  has ParameterNameValues => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::ParameterNameValue]', required => 1);
  has ResetAllParameters => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ResetCacheParameterGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::CacheParameterGroupNameMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ResetCacheParameterGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::ResetCacheParameterGroup - Arguments for method ResetCacheParameterGroup on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method ResetCacheParameterGroup on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method ResetCacheParameterGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ResetCacheParameterGroup.

As an example:

  $service_obj->ResetCacheParameterGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CacheParameterGroupName => Str

  

The name of the cache parameter group to reset.










=head2 B<REQUIRED> ParameterNameValues => ArrayRef[Paws::ElastiCache::ParameterNameValue]

  

An array of parameter names to be reset. If you are not resetting the
entire cache parameter group, you must specify at least one parameter
name.










=head2 ResetAllParameters => Bool

  

If I<true>, all parameters in the cache parameter group will be reset
to default values. If I<false>, no such action occurs.

Valid values: C<true> | C<false>












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ResetCacheParameterGroup in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

