use inc::Module::Install;

name 'Splunk-Conf';
#all_from 'lib/Splunk/Conf.pm';
version '0.1';
author 'Stan Sawa';
license 'hmm';

requires 'Moose';
requires 'LWP::UserAgent';
requires 'XML::Simple';
requires 'URI';
requires 'Carp';

WriteAll;
