
package Paws::DeviceFarm::CreateDevicePool {
  use Moose;
  has description => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str', required => 1);
  has projectArn => (is => 'ro', isa => 'Str', required => 1);
  has rules => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::Rule]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateDevicePool');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DeviceFarm::CreateDevicePoolResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::CreateDevicePool - Arguments for method CreateDevicePool on Paws::DeviceFarm

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateDevicePool on the 
AWS Device Farm service. Use the attributes of this class
as arguments to method CreateDevicePool.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateDevicePool.

As an example:

  $service_obj->CreateDevicePool(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 description => Str

  

The device pool's description.










=head2 B<REQUIRED> name => Str

  

The device pool's name.










=head2 B<REQUIRED> projectArn => Str

  

The ARN of the project for the device pool.










=head2 B<REQUIRED> rules => ArrayRef[Paws::DeviceFarm::Rule]

  

The device pool's rules.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateDevicePool in L<Paws::DeviceFarm>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

