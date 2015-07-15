
package Paws::ImportExport::GetStatus {
  use Moose;
  has APIVersion => (is => 'ro', isa => 'Str');
  has JobId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetStatus');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ImportExport::GetStatusOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'GetStatusResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ImportExport::GetStatus - Arguments for method GetStatus on Paws::ImportExport

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetStatus on the 
AWS Import/Export service. Use the attributes of this class
as arguments to method GetStatus.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetStatus.

As an example:

  $service_obj->GetStatus(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 APIVersion => Str

  

=head2 B<REQUIRED> JobId => Str

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetStatus in L<Paws::ImportExport>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

