
package Paws::EFS::DescribeMountTargets {
  use Moose;
  has FileSystemId => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'FileSystemId' , required => 1);
  has Marker => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'Marker' );
  has MaxItems => (is => 'ro', isa => 'Int', traits => ['ParamInQuery'], query_name => 'MaxItems' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeMountTargets');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-02-01/mount-targets');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EFS::DescribeMountTargetsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeMountTargetsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EFS::DescribeMountTargets - Arguments for method DescribeMountTargets on Paws::EFS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeMountTargets on the 
Amazon Elastic File System service. Use the attributes of this class
as arguments to method DescribeMountTargets.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeMountTargets.

As an example:

  $service_obj->DescribeMountTargets(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> FileSystemId => Str

  

String. The ID of the file system whose mount targets you want to list.










=head2 Marker => Str

  

Optional. String. Opaque pagination token returned from a previous
C<DescribeMountTargets> operation. If present, it specifies to continue
the list from where the previous returning call left off.










=head2 MaxItems => Int

  

Optional. Maximum number of mount targets to return in the response. It
must be an integer with a value greater than zero.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeMountTargets in L<Paws::EFS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

