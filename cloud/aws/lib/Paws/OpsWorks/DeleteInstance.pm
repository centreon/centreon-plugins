
package Paws::OpsWorks::DeleteInstance {
  use Moose;
  has DeleteElasticIp => (is => 'ro', isa => 'Bool');
  has DeleteVolumes => (is => 'ro', isa => 'Bool');
  has InstanceId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteInstance');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DeleteInstance - Arguments for method DeleteInstance on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteInstance on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method DeleteInstance.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteInstance.

As an example:

  $service_obj->DeleteInstance(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DeleteElasticIp => Bool

  

Whether to delete the instance Elastic IP address.










=head2 DeleteVolumes => Bool

  

Whether to delete the instance's Amazon EBS volumes.










=head2 B<REQUIRED> InstanceId => Str

  

The instance ID.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteInstance in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

