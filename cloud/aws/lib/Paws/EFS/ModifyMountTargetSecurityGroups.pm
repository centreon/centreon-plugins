
package Paws::EFS::ModifyMountTargetSecurityGroups {
  use Moose;
  has MountTargetId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'MountTargetId' , required => 1);
  has SecurityGroups => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyMountTargetSecurityGroups');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-02-01/mount-targets/{MountTargetId}/security-groups');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'PUT');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EFS::ModifyMountTargetSecurityGroups - Arguments for method ModifyMountTargetSecurityGroups on Paws::EFS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyMountTargetSecurityGroups on the 
Amazon Elastic File System service. Use the attributes of this class
as arguments to method ModifyMountTargetSecurityGroups.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyMountTargetSecurityGroups.

As an example:

  $service_obj->ModifyMountTargetSecurityGroups(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> MountTargetId => Str

  

The ID of the mount target whose security groups you want to modify.










=head2 SecurityGroups => ArrayRef[Str]

  

An array of up to five VPC security group IDs.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyMountTargetSecurityGroups in L<Paws::EFS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

