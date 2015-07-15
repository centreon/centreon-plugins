
package Paws::RedShift::ModifyClusterSubnetGroup {
  use Moose;
  has ClusterSubnetGroupName => (is => 'ro', isa => 'Str', required => 1);
  has Description => (is => 'ro', isa => 'Str');
  has SubnetIds => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyClusterSubnetGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::ModifyClusterSubnetGroupResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ModifyClusterSubnetGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::ModifyClusterSubnetGroup - Arguments for method ModifyClusterSubnetGroup on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyClusterSubnetGroup on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method ModifyClusterSubnetGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyClusterSubnetGroup.

As an example:

  $service_obj->ModifyClusterSubnetGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ClusterSubnetGroupName => Str

  

The name of the subnet group to be modified.










=head2 Description => Str

  

A text description of the subnet group to be modified.










=head2 B<REQUIRED> SubnetIds => ArrayRef[Str]

  

An array of VPC subnet IDs. A maximum of 20 subnets can be modified in
a single request.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyClusterSubnetGroup in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

