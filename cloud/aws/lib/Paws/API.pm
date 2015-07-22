package Paws::API::Attribute::Trait::Unwrapped {
  use Moose::Role;
  use Moose::Util;
  Moose::Util::meta_attribute_alias('Unwrapped');
  has xmlname => (is => 'ro', isa => 'Str');
}

package Paws::Net::Caller::Attribute::Trait::NameInRequest {
  use Moose::Role;
  use Moose::Util;
  Moose::Util::meta_attribute_alias('NameInRequest');
  has request_name => (is => 'ro', isa => 'Str');
}

package Paws::API::Attribute::Trait::ParamInHeader {
  use Moose::Role;
  use Moose::Util;
  Moose::Util::meta_attribute_alias('ParamInHeader');
  has header_name => (is => 'ro', isa => 'Str');
}

package Paws::API::Attribute::Trait::ParamInBody {
  use Moose::Role;
  use Moose::Util;
  Moose::Util::meta_attribute_alias('ParamInBody');
}

package Paws::API::Attribute::Trait::ParamInQuery {
  use Moose::Role;
  use Moose::Util;
  Moose::Util::meta_attribute_alias('ParamInQuery');
  has query_name => (is => 'ro', isa => 'Str');
}

package Paws::API::Attribute::Trait::ParamInURI {
  use Moose::Role;
  use Moose::Util;
  Moose::Util::meta_attribute_alias('ParamInURI');
  has uri_name => (is => 'ro', isa => 'Str');
}

1;
