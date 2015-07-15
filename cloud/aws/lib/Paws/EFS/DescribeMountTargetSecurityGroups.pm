
package Paws::EFS::DescribeMountTargetSecurityGroups {
  use Moose;
  has MountTargetId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'MountTargetId' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeMountTargetSecurityGroups');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-02-01/mount-targets/{MountTargetId}/security-groups');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EFS::DescribeMountTargetSecurityGroupsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeMountTargetSecurityGroupsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EFS::DescribeMountTargetSecurityGroups - Arguments for method DescribeMountTargetSecurityGroups on Paws::EFS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeMountTargetSecurityGroups on the 
Amazon Elastic File System service. Use the attributes of this class
as arguments to method DescribeMountTargetSecurityGroups.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeMountTargetSecurityGroups.

As an example:

  $service_obj->DescribeMountTargetSecurityGroups(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> MountTargetId => Str

  

The ID of the mount target whose security groups you want to retrieve.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeMountTargetSecurityGroups in L<Paws::EFS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

