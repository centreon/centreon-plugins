
package Paws::OpsWorks::DescribeVolumes {
  use Moose;
  has InstanceId => (is => 'ro', isa => 'Str');
  has RaidArrayId => (is => 'ro', isa => 'Str');
  has StackId => (is => 'ro', isa => 'Str');
  has VolumeIds => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeVolumes');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::OpsWorks::DescribeVolumesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeVolumes - Arguments for method DescribeVolumes on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeVolumes on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method DescribeVolumes.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeVolumes.

As an example:

  $service_obj->DescribeVolumes(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 InstanceId => Str

  

The instance ID. If you use this parameter, C<DescribeVolumes> returns
descriptions of the volumes associated with the specified instance.










=head2 RaidArrayId => Str

  

The RAID array ID. If you use this parameter, C<DescribeVolumes>
returns descriptions of the volumes associated with the specified RAID
array.










=head2 StackId => Str

  

A stack ID. The action describes the stack's registered Amazon EBS
volumes.










=head2 VolumeIds => ArrayRef[Str]

  

Am array of volume IDs. If you use this parameter, C<DescribeVolumes>
returns descriptions of the specified volumes. Otherwise, it returns a
description of every volume.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeVolumes in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

