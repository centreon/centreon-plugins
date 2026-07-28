package fixed_date;

# Copyright 2025-Present Centreon
# Always use the same fixed date to test certificate validity

BEGIN {
   *CORE::GLOBAL::time = sub { 1766401302 };
}

1
