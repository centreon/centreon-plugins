
package Paws::EC2::CreateSecurityGroup {
  use Moose;
  has Description => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'GroupDescription' , required => 1);
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has GroupName => (is => 'ro', isa => 'Str', required => 1);
  has VpcId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateSecurityGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::CreateSecurityGroupResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateSecurityGroup - Arguments for method CreateSecurityGroup on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateSecurityGroup on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CreateSecurityGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateSecurityGroup.

As an example:

  $service_obj->CreateSecurityGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Description => Str

  

A description for the security group. This is informational only.

Constraints: Up to 255 characters in length

Constraints for EC2-Classic: ASCII characters

Constraints for EC2-VPC: a-z, A-Z, 0-9, spaces, and
._-:/()










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 B<REQUIRED> GroupName => Str

  

The name of the security group.

Constraints: Up to 255 characters in length

Constraints for EC2-Classic: ASCII characters

Constraints for EC2-VPC: a-z, A-Z, 0-9, spaces, and
._-:/()










=head2 VpcId => Str

  

[EC2-VPC] The ID of the VPC. Required for EC2-VPC.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateSecurityGroup in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

