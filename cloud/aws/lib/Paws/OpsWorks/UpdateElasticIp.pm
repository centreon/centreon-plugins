
package Paws::OpsWorks::UpdateElasticIp {
  use Moose;
  has ElasticIp => (is => 'ro', isa => 'Str', required => 1);
  has Name => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateElasticIp');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::UpdateElasticIp - Arguments for method UpdateElasticIp on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateElasticIp on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method UpdateElasticIp.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateElasticIp.

As an example:

  $service_obj->UpdateElasticIp(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ElasticIp => Str

  

The address.










=head2 Name => Str

  

The new name.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateElasticIp in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

