
package Paws::CloudWatch::DeleteAlarms {
  use Moose;
  has AlarmNames => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteAlarms');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatch::DeleteAlarms - Arguments for method DeleteAlarms on Paws::CloudWatch

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteAlarms on the 
Amazon CloudWatch service. Use the attributes of this class
as arguments to method DeleteAlarms.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteAlarms.

As an example:

  $service_obj->DeleteAlarms(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AlarmNames => ArrayRef[Str]

  

A list of alarms to be deleted.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteAlarms in L<Paws::CloudWatch>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

