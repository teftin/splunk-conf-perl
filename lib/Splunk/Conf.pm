package Splunk::Conf;

use Moose;
use LWP::UserAgent;
use XML::Simple;
use URI;
use URI::Escape;
use Carp;
use 5.008001;
our $VERSION = '0.001';

has url => (
    is => 'ro',
    isa => 'Str',
    default => 'https://localhost:8089/services',
);

has skey => (
    is => 'rw',
    isa => 'Str',
);

has ua => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    lazy => 1,
    default => sub {
        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        $ua->agent('SNS::Splunk.pm(0.1)');
        return $ua;
    }
);

sub _url_for {
    my ( $self, $path ) = @_;
    return $self->url.$path;
}

sub _url_strip {
    my ( $self, $path ) = @_;
    my $base_path = $self->url;
    $path =~ s/^ $base_path //x;
    return $path;
}

sub login {
    my ( $self, $user, $pass ) = @_;
    $self->skey(''); #nuke current session key
    my $res = $self->req('/auth/login', 'POST',
                         username => $user,
                         password => $pass);
    my $res_d = XMLin($res->content);
    croak 'cannot log in' unless exists $res_d->{sessionKey};
    $self->skey($res_d->{sessionKey});
    return $res_d->{sessionKey};
}

sub req {
    my ( $self, $url, $meth, $body ) = @_;
    $meth = 'GET' unless $meth;
    my $req = HTTP::Request->new($meth => $self->_url_for($url));
    $req->header(Authorization => 'Splunk '.$self->skey) if $self->skey;
    if ( $body ) {
        if ( ref $body eq 'HASH' ) {
            $req->content( join '&', map { join '=', $_, $body->{$_} } keys %$body );
        }else {
            $req->content( $body );
        }
    }
    my $res = $self->ua->request($req);
    croak $url.': cannot do request '.$res->status_line unless $res->is_success;
    return $res->content;
}

sub path_for {
    my ( $self, @path ) = @_;
    join '/', '/properties', map { uri_escape($_) } @path;
}

sub list {
    my ( $self, @path ) = @_;
    my $list = XMLin($self->req($self->path_for(@path)))->{entry};
    return map { $list->{$_}->{title} } keys %$list;
}

sub stanza_create {
    my ( $self, $name, $stanza ) = @_;
    $self->req( $self->path_for($name), 'POST', { __stanza => $stanza } );
}

# splunk really only sets it to disabled
sub stanza_remove {
    my ( $self, $name, $stanza ) = @_;
    $self->req( $self->path_for($name, $stanza), 'DELETE' );
}

sub stanza_attrib_update {
    my ( $self, $name, $stanza, %kv ) = @_;
    $self->req( $self->path_for($name, $stanza), 'POST', \%kv );
}

sub stanza_attrib_replace {
    my ( $self, $name, $stanza, %kv ) = @_;
    $self->req( $self->path_for($name, $stanza), 'PUT', \%kv );
}

sub stanza_attrib_kv {
    my ( $self, $name, $stanza ) = @_;
    my $list = XMLin($self->req($self->path_for($name, $stanza)))->{entry};
    return map { $list->{$_}->{title}, $list->{$_}->{content}->{content} } keys %$list;
}

=head1 NAME

Splunk::Conf - access/modify splunk configuration

=head1 SYNOPSIS

use Splunk::Conf;

eval {
  my $splunk = Splunk::Conf->new;
  $splunk->login('admin', 'changeme');

  my @stanza_list = $splunk->list('inputs');
  $splunk->stanza_create('inputs', 'monitor:///hello/world');
  $splunk->stanza_attrib_update('inputs', 'monitor:///hello/world',
    disabled => 'false',
    host_segment => 3,
    sourcetype => 'syslog');
  my %attribs = $splunk->stanza_attrib_kv('inputs', 'monitor:///hello/world');
};
if ($@) {
  print 'error: '.$@;
}

=head1 DESCRIPTION

This is simple module using splunk rest api to access/modify splunk
configuration.
It tries to hind underlying REST api in somewhat-procedural interface

=head1 TODO

- oo. wrap files/stanzas in objects
- better error handling
- docs
- handle other endpoints

=head1 AUTHOR

Stanislaw Sawa - stanislaw.sawa (at) sns.bskyb.com

=head1 LICENSE

Copyright (C) 2008 Sky Network Services. All Rights Reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

42;
