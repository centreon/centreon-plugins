
package Paws::RedShift::RevokeClusterSecurityGroupIngress {
  use Moose;
  has CIDRIP => (is => 'ro', isa => 'Str');
  has ClusterSecurityGroupName => (is => 'ro', isa => 'Str', required => 1);
  has EC2SecurityGroupName => (is => 'ro', isa => 'Str');
  has EC2SecurityGroupOwnerId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RevokeClusterSecurityGroupIngress');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::RevokeClusterSecurityGroupIngressResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'RevokeClusterSecurityGroupIngressResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::RevokeClusterSecurityGroupIngress - Arguments for method RevokeClusterSecurityGroupIngress on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method RevokeClusterSecurityGroupIngress on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method RevokeClusterSecurityGroupIngress.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RevokeClusterSecurityGroupIngress.

As an example:

  $service_obj->RevokeClusterSecurityGroupIngress(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CIDRIP => Str

  

The IP range for which to revoke access. This range must be a valid
Classless Inter-Domain Routing (CIDR) block of IP addresses. If
C<CIDRIP> is specified, C<EC2SecurityGroupName> and
C<EC2SecurityGroupOwnerId> cannot be provided.










=head2 B<REQUIRED> ClusterSecurityGroupName => Str

  

The name of the security Group from which to revoke the ingress rule.










=head2 EC2SecurityGroupName => Str

  

The name of the EC2 Security Group whose access is to be revoked. If
C<EC2SecurityGroupName> is specified, C<EC2SecurityGroupOwnerId> must
also be provided and C<CIDRIP> cannot be provided.










=head2 EC2SecurityGroupOwnerId => Str

  

The AWS account number of the owner of the security group specified in
the C<EC2SecurityGroupName> parameter. The AWS access key ID is not an
acceptable value. If C<EC2SecurityGroupOwnerId> is specified,
C<EC2SecurityGroupName> must also be provided. and C<CIDRIP> cannot be
provided.

Example: C<111122223333>












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RevokeClusterSecurityGroupIngress in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

