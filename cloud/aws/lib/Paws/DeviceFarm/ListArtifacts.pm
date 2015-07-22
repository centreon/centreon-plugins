
package Paws::DeviceFarm::ListArtifacts {
  use Moose;
  has arn => (is => 'ro', isa => 'Str', required => 1);
  has nextToken => (is => 'ro', isa => 'Str');
  has type => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListArtifacts');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DeviceFarm::ListArtifactsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::ListArtifacts - Arguments for method ListArtifacts on Paws::DeviceFarm

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListArtifacts on the 
AWS Device Farm service. Use the attributes of this class
as arguments to method ListArtifacts.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListArtifacts.

As an example:

  $service_obj->ListArtifacts(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> arn => Str

  

The artifacts' ARNs.










=head2 nextToken => Str

  

An identifier that was returned from the previous call to this
operation, which can be used to return the next set of items in the
list.










=head2 B<REQUIRED> type => Str

  

The artifacts' type.

Allowed values include:

=over

=item * FILE: The artifacts are files.

=item * LOG: The artifacts are logs.

=item * SCREENSHOT: The artifacts are screenshots.

=back












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListArtifacts in L<Paws::DeviceFarm>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

