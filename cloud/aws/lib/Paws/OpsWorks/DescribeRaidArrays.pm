
package Paws::OpsWorks::DescribeRaidArrays {
  use Moose;
  has InstanceId => (is => 'ro', isa => 'Str');
  has RaidArrayIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has StackId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeRaidArrays');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::OpsWorks::DescribeRaidArraysResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeRaidArrays - Arguments for method DescribeRaidArrays on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeRaidArrays on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method DescribeRaidArrays.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeRaidArrays.

As an example:

  $service_obj->DescribeRaidArrays(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 InstanceId => Str

  

The instance ID. If you use this parameter, C<DescribeRaidArrays>
returns descriptions of the RAID arrays associated with the specified
instance.










=head2 RaidArrayIds => ArrayRef[Str]

  

An array of RAID array IDs. If you use this parameter,
C<DescribeRaidArrays> returns descriptions of the specified arrays.
Otherwise, it returns a description of every array.










=head2 StackId => Str

  

The stack ID.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeRaidArrays in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

