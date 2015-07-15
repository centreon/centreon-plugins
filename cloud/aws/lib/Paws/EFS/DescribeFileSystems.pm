
package Paws::EFS::DescribeFileSystems {
  use Moose;
  has CreationToken => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'CreationToken' );
  has FileSystemId => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'FileSystemId' );
  has Marker => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'Marker' );
  has MaxItems => (is => 'ro', isa => 'Int', traits => ['ParamInQuery'], query_name => 'MaxItems' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeFileSystems');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-02-01/file-systems');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EFS::DescribeFileSystemsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeFileSystemsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EFS::DescribeFileSystems - Arguments for method DescribeFileSystems on Paws::EFS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeFileSystems on the 
Amazon Elastic File System service. Use the attributes of this class
as arguments to method DescribeFileSystems.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeFileSystems.

As an example:

  $service_obj->DescribeFileSystems(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CreationToken => Str

  

Optional string. Restricts the list to the file system with this
creation token (you specify a creation token at the time of creating an
Amazon EFS file system).










=head2 FileSystemId => Str

  

Optional string. File system ID whose description you want to retrieve.










=head2 Marker => Str

  

Optional string. Opaque pagination token returned from a previous
C<DescribeFileSystems> operation. If present, specifies to continue the
list from where the returning call had left off.










=head2 MaxItems => Int

  

Optional integer. Specifies the maximum number of file systems to
return in the response. This parameter value must be greater than 0.
The number of items Amazon EFS returns will be the minimum of the
C<MaxItems> parameter specified in the request and the service's
internal maximum number of items per page.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeFileSystems in L<Paws::EFS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

