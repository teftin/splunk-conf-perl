use inc::Module::Install;

name 'Splunk-Conf';
all_from 'lib/Splunk/Conf.pm';

requires 'Moose';
requires 'LWP::UserAgent';
requires 'XML::Simple';
requires 'URI';
requires 'Carp';

auto_install;
WriteAll;
