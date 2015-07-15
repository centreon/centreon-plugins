
package Paws::RedShift::AuthorizeClusterSecurityGroupIngress {
  use Moose;
  has CIDRIP => (is => 'ro', isa => 'Str');
  has ClusterSecurityGroupName => (is => 'ro', isa => 'Str', required => 1);
  has EC2SecurityGroupName => (is => 'ro', isa => 'Str');
  has EC2SecurityGroupOwnerId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AuthorizeClusterSecurityGroupIngress');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::AuthorizeClusterSecurityGroupIngressResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'AuthorizeClusterSecurityGroupIngressResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::AuthorizeClusterSecurityGroupIngress - Arguments for method AuthorizeClusterSecurityGroupIngress on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method AuthorizeClusterSecurityGroupIngress on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method AuthorizeClusterSecurityGroupIngress.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AuthorizeClusterSecurityGroupIngress.

As an example:

  $service_obj->AuthorizeClusterSecurityGroupIngress(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CIDRIP => Str

  

The IP range to be added the Amazon Redshift security group.










=head2 B<REQUIRED> ClusterSecurityGroupName => Str

  

The name of the security group to which the ingress rule is added.










=head2 EC2SecurityGroupName => Str

  

The EC2 security group to be added the Amazon Redshift security group.










=head2 EC2SecurityGroupOwnerId => Str

  

The AWS account number of the owner of the security group specified by
the I<EC2SecurityGroupName> parameter. The AWS Access Key ID is not an
acceptable value.

Example: C<111122223333>












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AuthorizeClusterSecurityGroupIngress in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

