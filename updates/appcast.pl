#!/usr/bin/perl

use strict;
use warnings;

use HTML::Template;
use HTTP::Date;

my %config = (
	      app_title => "GitX (R)",
	      base_url => "http://builds.phere.net/"
	     );

my $template_text = <<EO_TMPL;
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"  xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title><TMPL_VAR APP_TITLE> Changelog</title>
    <link><TMPL_VAR BASE_URL><TMPL_VAR BUILD_BASENAME>.xml</link>
    <description>Most recent changes with links to updates.</description>
    <language>en</language>

    <item>
      <title><TMPL_VAR APP_TITLE> <TMPL_VAR BUILD_TYPE> <TMPL_VAR CFBUNDLEVERSION></title>
      <sparkle:releaseNotesLink><TMPL_VAR BASE_URL><TMPL_VAR BUILD_BASENAME>-<TMPL_VAR BUILD_NUMBER>.html</sparkle:releaseNotesLink>
      <sparkle:minimumSystemVersion>10.6.0</sparkle:minimumSystemVersion>
      <pubDate><TMPL_VAR PUBDATE></pubDate>
      <enclosure url="<TMPL_VAR BASE_URL><TMPL_VAR BUILD_BASENAME>-<TMPL_VAR BUILD_NUMBER>.zip" sparkle:version="<TMPL_VAR CFBUNDLEVERSION>" length="<TMPL_VAR FILE_SIZE>" sparkle:dsaSignature="<TMPL_VAR FILE_SIG>" type="application/octet-stream" />
    </item>

  </channel>
</rss>
EO_TMPL
    
my $tmpl = HTML::Template->new( scalarref => \$template_text );

$tmpl->param(
	     base_url => $config{base_url},
	     app_title => $config{app_title},
	     build_basename => $ENV{BUILD_BASENAME},
	     CFBundleVersion => $ENV{BUILD_BASENAME},
	     build_number => $ENV{BUILD_NUMBER},
	     PubDate => time2str(),
	     file_size => $ENV{BUILD_FILESIZE},
    file_sig => $ENV{BUILD_SIGNATURE},
    build_type => $ENV{BULID_TYPE},
	    );

print $tmpl->output;

