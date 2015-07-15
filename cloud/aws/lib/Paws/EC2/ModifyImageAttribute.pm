
package Paws::EC2::ModifyImageAttribute {
  use Moose;
  has Attribute => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Paws::EC2::AttributeValue');
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has ImageId => (is => 'ro', isa => 'Str', required => 1);
  has LaunchPermission => (is => 'ro', isa => 'Paws::EC2::LaunchPermissionModifications');
  has OperationType => (is => 'ro', isa => 'Str');
  has ProductCodes => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'ProductCode' );
  has UserGroups => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'UserGroup' );
  has UserIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'UserId' );
  has Value => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyImageAttribute');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ModifyImageAttribute - Arguments for method ModifyImageAttribute on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyImageAttribute on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method ModifyImageAttribute.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyImageAttribute.

As an example:

  $service_obj->ModifyImageAttribute(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Attribute => Str

  

The name of the attribute to modify.










=head2 Description => Paws::EC2::AttributeValue

  

A description for the AMI.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 B<REQUIRED> ImageId => Str

  

The ID of the AMI.










=head2 LaunchPermission => Paws::EC2::LaunchPermissionModifications

  

A launch permission modification.










=head2 OperationType => Str

  

The operation type.










=head2 ProductCodes => ArrayRef[Str]

  

One or more product codes. After you add a product code to an AMI, it
can't be removed. This is only valid when modifying the C<productCodes>
attribute.










=head2 UserGroups => ArrayRef[Str]

  

One or more user groups. This is only valid when modifying the
C<launchPermission> attribute.










=head2 UserIds => ArrayRef[Str]

  

One or more AWS account IDs. This is only valid when modifying the
C<launchPermission> attribute.










=head2 Value => Str

  

The value of the attribute being modified. This is only valid when
modifying the C<description> attribute.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyImageAttribute in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

