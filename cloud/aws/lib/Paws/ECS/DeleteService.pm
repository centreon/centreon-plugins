
package Paws::ECS::DeleteService {
  use Moose;
  has cluster => (is => 'ro', isa => 'Str');
  has service => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteService');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ECS::DeleteServiceResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECS::DeleteService - Arguments for method DeleteService on Paws::ECS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteService on the 
Amazon EC2 Container Service service. Use the attributes of this class
as arguments to method DeleteService.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteService.

As an example:

  $service_obj->DeleteService(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 cluster => Str

  

The name of the cluster that hosts the service you want to delete.










=head2 B<REQUIRED> service => Str

  

The name of the service you want to delete.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteService in L<Paws::ECS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

