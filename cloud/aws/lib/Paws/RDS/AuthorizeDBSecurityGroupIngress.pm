
package Paws::RDS::AuthorizeDBSecurityGroupIngress {
  use Moose;
  has CIDRIP => (is => 'ro', isa => 'Str');
  has DBSecurityGroupName => (is => 'ro', isa => 'Str', required => 1);
  has EC2SecurityGroupId => (is => 'ro', isa => 'Str');
  has EC2SecurityGroupName => (is => 'ro', isa => 'Str');
  has EC2SecurityGroupOwnerId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AuthorizeDBSecurityGroupIngress');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::AuthorizeDBSecurityGroupIngressResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'AuthorizeDBSecurityGroupIngressResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::AuthorizeDBSecurityGroupIngress - Arguments for method AuthorizeDBSecurityGroupIngress on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method AuthorizeDBSecurityGroupIngress on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method AuthorizeDBSecurityGroupIngress.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AuthorizeDBSecurityGroupIngress.

As an example:

  $service_obj->AuthorizeDBSecurityGroupIngress(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CIDRIP => Str

  

The IP range to authorize.










=head2 B<REQUIRED> DBSecurityGroupName => Str

  

The name of the DB security group to add authorization to.










=head2 EC2SecurityGroupId => Str

  

Id of the EC2 security group to authorize. For VPC DB security groups,
C<EC2SecurityGroupId> must be provided. Otherwise,
EC2SecurityGroupOwnerId and either C<EC2SecurityGroupName> or
C<EC2SecurityGroupId> must be provided.










=head2 EC2SecurityGroupName => Str

  

Name of the EC2 security group to authorize. For VPC DB security
groups, C<EC2SecurityGroupId> must be provided. Otherwise,
EC2SecurityGroupOwnerId and either C<EC2SecurityGroupName> or
C<EC2SecurityGroupId> must be provided.










=head2 EC2SecurityGroupOwnerId => Str

  

AWS Account Number of the owner of the EC2 security group specified in
the EC2SecurityGroupName parameter. The AWS Access Key ID is not an
acceptable value. For VPC DB security groups, C<EC2SecurityGroupId>
must be provided. Otherwise, EC2SecurityGroupOwnerId and either
C<EC2SecurityGroupName> or C<EC2SecurityGroupId> must be provided.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AuthorizeDBSecurityGroupIngress in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

