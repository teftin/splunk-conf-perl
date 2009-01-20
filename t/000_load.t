use Test::More no_plan => 1;

BEGIN {
      use_ok('Splunk::Conf');
}

isa(Splunk::Conf, 'Moose::Object', '... this is properly moosed');