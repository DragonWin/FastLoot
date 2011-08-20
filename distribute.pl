#! c:\perl\bin\perl.exe
use strict;
use warnings;
use Archive::Zip;
use FindBin qw($Bin);
use File::Copy;
require LWP::UserAgent;
require HTTP::Request::Common;
require HTTP::Cookies;


print "What version should this be?\n";
print "(y.xx): ";
my $version = <STDIN>;
chomp $version;
if ($version !~ /[0-9]\.[0-9][0-9]/) {
    print "Version number must be in the format y.xx\n";
	die;
}

my $filename = "FastLoot_" . $version . ".zip";

my %website;
my $ua = GetUA();
my $response = $ua->get('http://floot.xpoints.dk/download/versions.html');
if ( $response->is_success() ) {
	my $content = $response->content();
	my @lines = split(/;/, $content);
	foreach (@lines) {
		chomp;  
		s/#.*//;                # no comments
		s/^\s+//;               # no leading white
		s/\s+$//;               # no trailing white
		next unless length;     # anything left?
		my ($var, $value) = split(/\s*=\s*/, $_, 2);
		$website{$var} = $value;
	}
}

open(HTML, ">$Bin/versions.html");
while (my ($key, $value) = each(%website) ) {
	if ($key =~ /^FastLoot$/) {
		print HTML $key . " = " . $version . ";\n";
	} else {
		print HTML $key . " = " . $value . ";\n";
	}
}
close(HTML);


# And Zip it.
# print "Zipping the files"
my $zip = Archive::Zip->new();
$zip->addTreeMatching("$Bin" , 'FastLoot' , '\.lua$');
$zip->addTreeMatching("$Bin" , 'FastLoot' , '\.toc$');
$zip->addTreeMatching("$Bin" , 'FastLoot' , '\.mp3$');
$zip->addTreeMatching("$Bin/../Ace3" , 'Ace3', '.*');

$zip->writeToFileNamed("$filename");

move("$filename", "Y:/html/floot/download/$filename");
move("versions.html", "Y:/html/floot/download/versions.html");

sub GetUA {
    my $ua = LWP::UserAgent->new();
    $ua->timeout(10);
    $ua->agent("Doa Uploader/0.1"); # pretend we are very capable browser :)
#    $ua->proxy(['http'], 'http://localhost:8080');
    return $ua;
}

