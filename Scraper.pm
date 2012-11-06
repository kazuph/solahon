use strict;
use warnings;
use autodie;
use File::Basename;
use File::Spec;
use LWP::UserAgent;
use Web::Query;
use DBI;
use YAML::XS;
use DateTime;
use URI::Escape;

my $dsn   = "DBI:mysql:solahon";
my $user  = "root";
my $password = "pcvl82";

my $tzhere = DateTime::TimeZone->new( name => 'local' );
my $dbh = DBI->connect($dsn,$user,$password,{RaiseError => 1, PrintError => 0, AutoCommit => 0}) || die "$!";

my $ua = LWP::UserAgent->new;
my $baseurl = 'http://photojournal.jpl.nasa.gov';
my @target  = ('Sun','Mercury','Venus','Earth','Mars');

foreach my $target (@target){
	my $url     = $baseurl.'/targetFamily/'.$target;
	print 'url is '.$url;
	wq($url)
		->find('a')
    		->each(sub {
        		if($_->attr('href')=~/jpeg/){
			my $image_url = $baseurl.$_->attr('href');
			my $dt = DateTime->now(time_zone => $tzhere);
        		print "Target: $target Downloading: $image_url\n";
        		
			#insert into db
			eval{
			  &insertdata($target,$image_url);
			};
			if($@){
			  $dbh->rollback;
   			  $dbh->disconnect;
			}
		}
    	});
}
$dbh->disconnect;

exit 0;

#--------------------------------------------------------------------
sub insertdata {
  my($target,$image_url) = @_;
  my $sql = "insert into image (image_url,target,created_on) values (\"".$image_url. "\",\"".$target."\",now())";
  my $sth = $dbh->prepare($sql);
  $sth->execute;
  $dbh->commit;
}

