
package Paws::EC2::ModifySnapshotAttribute {
  use Moose;
  has Attribute => (is => 'ro', isa => 'Str');
  has CreateVolumePermission => (is => 'ro', isa => 'Paws::EC2::CreateVolumePermissionModifications');
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has GroupNames => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'UserGroup' );
  has OperationType => (is => 'ro', isa => 'Str');
  has SnapshotId => (is => 'ro', isa => 'Str', required => 1);
  has UserIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'UserId' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifySnapshotAttribute');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ModifySnapshotAttribute - Arguments for method ModifySnapshotAttribute on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifySnapshotAttribute on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method ModifySnapshotAttribute.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifySnapshotAttribute.

As an example:

  $service_obj->ModifySnapshotAttribute(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Attribute => Str

  

The snapshot attribute to modify.










=head2 CreateVolumePermission => Paws::EC2::CreateVolumePermissionModifications

  

A JSON representation of the snapshot attribute modification.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 GroupNames => ArrayRef[Str]

  

The group to modify for the snapshot.










=head2 OperationType => Str

  

The type of operation to perform to the attribute.










=head2 B<REQUIRED> SnapshotId => Str

  

The ID of the snapshot.










=head2 UserIds => ArrayRef[Str]

  

The account ID to modify for the snapshot.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifySnapshotAttribute in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

