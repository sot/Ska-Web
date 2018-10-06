package Ska::Web;

use 5.008;
use strict;
use warnings;
use LWP::UserAgent;
use HTML::TreeBuilder;
use Data::Dumper;
use URI;
use Carp;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
				   get_url
				   get_url_content 
				   get_html_content
                                   get_user_passwd
				  ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
		);
our $VERSION = '4.0';
our $Accumulate;
our $Accumulate_depth;
our @Accumulate_img_src;
our %filter;

####################################################################################
sub get_url {
####################################################################################
    my $url = shift;
    my %opt = (timeout => 60,
	       @_);

    my $user_agent = LWP::UserAgent->new;
    $user_agent->timeout($opt{timeout});
    my $req = HTTP::Request->new(GET => $url);
    $req->authorization_basic($opt{user}, $opt{passwd})
      if (defined $opt{user} and defined $opt{passwd});

    
    my $response = $user_agent->request($req);
    if ($response->is_success) {
	return wantarray ? ($response->content, undef, $response->{_headers}) : $response->content;
    } else {
	return wantarray ? (undef, $response->status_line, undef) : undef;
    }
}

##***************************************************************************
sub get_user_passwd {
# Get get username and password configuration
# data from Config::General format file(s).  Croaks if unsuccessful.
# 
# Input: file glob specifying files to try reading.
# Output: (username, password)
##***************************************************************************
    eval "use Config::General qw(ParseConfig)";
    croak $@ if $@;

    my $auth_file_glob = shift;

    foreach my $filename (glob $auth_file_glob) {
        if (-r $filename) {
            my %authinfo = ParseConfig(-ConfigFile => $filename);
            if (defined $authinfo{username} and defined $authinfo{password}) {
                return ($authinfo{username}, $authinfo{password});
            }
        }
    }
    croak "Failed to get a valid username and password from $auth_file_glob";
}

####################################################################################
sub get_url_content {
####################################################################################
    my $url = shift;
    my %opt = (url => $url,
	       @_);
    my ($html, $error) = get_url($url, %opt);
    return (undef, $error) if defined $error;
    return get_html_content($html, %opt);
}

####################################################################################
sub get_html_content {
####################################################################################
    my $html = shift;
    my %opt = @_;
    local $_;
    undef $Accumulate;
    undef $Accumulate_depth;
    undef @Accumulate_img_src;
    %filter = $opt{filter} ? %{$opt{filter}} : ();

    my $tree = HTML::TreeBuilder->new();
    $tree->parse($html);
    $tree->eof();

    # Check if it seems to be actual HTML by seeing if every HTML
    # element from parse is actually implicit
    if (grep { not $_->implicit } $tree->descendants) {
	traverse($tree, 0)
    } else {
	$Accumulate = $html;
    }

    my $content;
    if (defined $Accumulate) {
	my $pre = $opt{pre} || '\A';
	my $post = $opt{post} || '\Z';
	($content) = ($Accumulate =~ /$pre(.*?)$post/ms);
    }

    my @images;
    my $dummy_url = 'http://This_is_a_dummy_URL_that_does_not_exist';
    foreach my $src (@Accumulate_img_src) {
	my $base_uri = URI->new($opt{url} || $dummy_url);
	my $uri = URI->new($src);
	my $img_uri = $uri->abs($base_uri);
	next if $img_uri =~ /$dummy_url/; # No base URL supplied and src is relative
	my ($image_data, $error, $header) = get_url($img_uri);
	push @images, {data => $image_data,
		       name => $img_uri->rel($img_uri)->as_string,
		       url  => $img_uri->as_string,
                       header => $header,
		      } unless defined $error;
    }	
    
    return ($content, undef, @images);
}

####################################################################################
sub traverse {
####################################################################################
    my $h = shift;
    my $depth = shift;
    local $_;
    my $tab = ' ' x ($depth*2);
    my %attr = $h->all_external_attr;
    my @attr = map { "$_=$attr{$_}" } keys %attr;
    
    my $match = 1;
    foreach (keys %filter) {
	$match = 0 if ($_ eq 'tag') ? $h->tag ne $filter{$_} 
	  : (not defined $h->attr($_)) || ($h->attr($_) !~ /$filter{$_}/);
    }

    push @Accumulate_img_src, $h->attr('src') if ($match and defined $filter{tag}
						  and $filter{tag} eq 'img' and $h->tag eq 'img');

    if ($match and not defined $Accumulate_depth) {
	$Accumulate_depth = $depth;
    }

    if (not $match
	and defined $Accumulate_depth
	and $depth < $Accumulate_depth) {
	undef $Accumulate_depth;
    }

    foreach my $child ($h->content_list) {
        if (ref $child and $child->isa('HTML::Element')) { 
            traverse($child, $depth+1);
        } else {
	    $Accumulate .=  "$child\n" if defined $Accumulate_depth;
        }
    }
}



1;
__END__

=head1 NAME

Ska::Web - Utilities related to Perl web access

=head1 SYNOPSIS

  use Ska::Web qw(:all);
  ($html, $error) = get_url('http://sec.noaa.gov/rt_plots/xray_5m.html'
                            user   => $username,
                            passwd => $password,
                            timeout => 120, # Seconds
                           );
  $html = get_url('http://sec.noaa.gov/rt_plots/xray_5m.html');

  ($content, $error, @images) = get_url_content('http://asc.harvard.edu/mta/G11.html',
						filter => {tag => 'img',
							   alt => 'space weather'
							  }
					       );

  ($content, $error) = get_url_content('http://asc.harvard.edu/mta/G11.html',
				       pre => 'Proton Flux',
				       post => 's-sr-MeV',
				       filter => {tag => 'pre' }
				      );


  ($content, $error) = get_url_content('file:///proj/rac/ops/CRM2/CRMsummary.dat',
				       pre => 'Currently scheduled FPSI, OTG :',
				       post => '$',
				      );


  ($content, $error) = get_html_content($html,
				       pre => 'Proton Flux',
				       post => 's-sr-MeV',
				       filter => {tag => 'pre' }
				      );


=head1 DESCRIPTION

The simple get_url() utility is used to fetch content from the web.  This
includes the facility to access password-protected sites and set a timeout
(default = 60 seconds). In array context, get_url() returns the content and any
error message.  In scalar context only the content is returned.  In both cases
the content will be undefined if the Web request was not successful.

Get_url_content() fetches the content of any valid URL (including http://,
ftp://, and file://) and then returns filtered content and/or
image data from that page.  The matched images are returned as an array of  
hash references with the keys 'data', 'name', and 'url'.
 
Get_html_content() is the same as get_url_content() except that the supplied
input is the actual HTML (previously fetched with get_url() for instance) 
instead of a URL.

=head1 EXPORT

None by default.

=head1 AUTHOR

Tom Aldcroft, E<lt>aldcroft@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Tom Aldcroft

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
