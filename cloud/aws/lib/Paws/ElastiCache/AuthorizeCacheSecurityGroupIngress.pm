
package Paws::ElastiCache::AuthorizeCacheSecurityGroupIngress {
  use Moose;
  has CacheSecurityGroupName => (is => 'ro', isa => 'Str', required => 1);
  has EC2SecurityGroupName => (is => 'ro', isa => 'Str', required => 1);
  has EC2SecurityGroupOwnerId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AuthorizeCacheSecurityGroupIngress');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::AuthorizeCacheSecurityGroupIngressResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'AuthorizeCacheSecurityGroupIngressResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::AuthorizeCacheSecurityGroupIngress - Arguments for method AuthorizeCacheSecurityGroupIngress on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method AuthorizeCacheSecurityGroupIngress on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method AuthorizeCacheSecurityGroupIngress.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AuthorizeCacheSecurityGroupIngress.

As an example:

  $service_obj->AuthorizeCacheSecurityGroupIngress(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CacheSecurityGroupName => Str

  

The cache security group which will allow network ingress.










=head2 B<REQUIRED> EC2SecurityGroupName => Str

  

The Amazon EC2 security group to be authorized for ingress to the cache
security group.










=head2 B<REQUIRED> EC2SecurityGroupOwnerId => Str

  

The AWS account number of the Amazon EC2 security group owner. Note
that this is not the same thing as an AWS access key ID - you must
provide a valid AWS account number for this parameter.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AuthorizeCacheSecurityGroupIngress in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

