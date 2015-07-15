
package Paws::RedShift::DisableLogging {
  use Moose;
  has ClusterIdentifier => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DisableLogging');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::LoggingStatus');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DisableLoggingResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::DisableLogging - Arguments for method DisableLogging on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method DisableLogging on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method DisableLogging.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DisableLogging.

As an example:

  $service_obj->DisableLogging(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ClusterIdentifier => Str

  

The identifier of the cluster on which logging is to be stopped.

Example: C<examplecluster>












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DisableLogging in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

