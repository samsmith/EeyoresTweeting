#!/usr/bin/perl -w
use strict;

my $tweeting_enabled=1;

warn "tweeting disabled" unless $tweeting_enabled;

#http://www.windley.com/archives/2009/01/a_retweeter_in_perl.shtml

my $user = 'EeyoresTweeting';
my $consumer_key        = "..................";
my $consumer_secret     = '..................';
my $access_token        = '..................';
my $access_token_secret = '..................';
my @quotes= ( "quote 1",
	      'quote 2'
	    );

my @to_eeyore= ("Good morning... XXX ... If it is a good morning... Which I doubt", 
		"It just shows what can be done by taking a little trouble, Do you see, XXX? Brains first and then Hard Work.",
		"XXX At least we haven't had an earthquake lately."
		);

use Net::Twitter;
use DateTime;
use Fcntl;
use SDBM_File;
use File::Copy;
#die;

my $dt = DateTime->now;
$dt->subtract( minutes => 60); 

#my $class = 'DateTime::Format::HTTP';
#my $since = $class->format_datetime($dt);
my %seen_this_time;
my @localtime= localtime;
my $year= $localtime[5]+1900;

chdir ("$ENV{HOME}/work/eeyore-twitter/");
my $today_string = $dt->strftime("%M");
my $seen_dir = "./seen";
my $seen_file = "$seen_dir/latest.db";
my $backup_file = "$seen_dir/$today_string.db";

# make a backup of the hash and open it
unless(-e "$backup_file.pag") {
    copy("$seen_file.pag","$backup_file.pag");
    copy("$seen_file.dir","$backup_file.dir");
}

my %seen;
tie %seen, "SDBM_File", $seen_file, O_CREAT|O_RDWR, 0644 || die "Can't tie to $seen_file, $!\n";
my $twit;

# set your own username and password here
&login;

sub login {
  	$twit = Net::Twitter->new(
      		traits   => [qw/OAuth API::REST API::Search/],
      		consumer_key        => $consumer_key,
      		consumer_secret     => $consumer_secret,
      		access_token        => $access_token,
      		access_token_secret => $access_token_secret

  	);
 	unless ( 0 || $twit->authorized ) {
  		# The client is not yet authorized: Do it now
    		print "Authorize this app at ", $twit->get_authorization_url, " and enter the PIN#\n";

 			#die;
      		my $pin = <STDIN>; # wait for input
      		chomp $pin;

      		my($access_token, $access_token_secret, $user_id, $screen_name) = $twit->request_access_token(verifier => $pin);
      		warn join "\n",  $access_token, $access_token_secret; # if necessary
	}
}


die "unauthorized" unless $twit->authorized;

# find replies
my $retweets = [];
my $twit_replies = $twit->home_timeline({since => $dt, count=>100}) ;
my $reply_count=0;
$seen_this_time{$user}=1; # dont tweet at self

foreach my $reply (@{ $twit_replies }) {
  my $text = $reply->{'text'};
  my $id = $reply->{'id'};
  last if $reply_count == 3;
  my $name = $reply->{'user'}->{'screen_name'};
  #print ".";
  if($text =~ m/eeyore/  && ! $seen{$id} ){
	#pick a random quote from the collection and @ it
	my $msg= &random_tweet(\@to_eeyore);
	next if $msg =~ m#morning# and $localtime[2] > 11;
	$msg=~ s#XXX#$reply->{'name'}#;
	warn $msg unless $tweeting_enabled;
	next if $name=~ /habarosen/i; # another bot
	next if $name=~ /tigger/i; # another bot
	next if $name=~ /eeyore/i; # another bot
	next if $name=~ /disney/i; # another bot
	next if $seen_this_time{$name};
	$seen_this_time{$name}=1;
  	$twit->update($msg,{ in_reply_to_status_id => $id}) if $tweeting_enabled;
  	#warn "would_tweet $status";
  	$seen{$id} = 1 ;
  }
  sleep (13 * 60); # 13 mins.
  $reply_count++;

}


if ($reply_count < 3) {
	my $twit_replies = $twit->search("eeyore");
	# pick a generic quote and tweet it.	
	for my $status ( @{$twit_replies->{results}} ) {
		next if $status->{text} !~ /^(\@\w+)/;
		my $target_user= $1;

  		next if $seen{$status->{'id'}};
  		$seen{$status->{'id'}} = 1 ;
  		last if $reply_count == 3;
		next if $seen_this_time{$target_user};
		if (defined $seen{$target_user} == $year) {
			next if $seen{$target_user} == $year ;
		}
		$seen{$target_user}= $year;
		$reply_count++;


		my $msg= &random_tweet(\@quotes);
		if ($msg=~ s#XXX#$target_user#) {
			# name embedded in msg now
		} else {
			$msg= "$target_user $msg";
		}
		next if $msg =~ m#morning# and $localtime[2] > 11;
		#warn "generics would tweet: $msg;"; next;
		warn $msg unless $tweeting_enabled;
		my $replyid= $status->{'in_reply_to_status_id'} || $status->{'id'};
		next if $target_user=~ /habarosen/i; # another bot
		next if $target_user=~ /eeyore/i; # another bot
		next if $target_user=~ /tigger/i; # another bot
		next if $target_user=~ /disney/i; # another bot
		$twit->update($msg, {in_reply_to_status_id => $replyid}) if $tweeting_enabled;
	}

}

if ($reply_count == 0  and (rand() > 0.5) ){ # if not tweeted yet
	#pick random quote and tweet it
	my $msg= &random_tweet(\@quotes);
	warn $msg unless $tweeting_enabled;
	unless ( $msg =~ m#morning# and $localtime[2] > 11) {
		$twit->update($msg) if $tweeting_enabled;
	}
	#warn "would tweet: $msg;"; next;
}





sub random_tweet{
	my $list_ref=shift;
	my @items= @{$list_ref};
	my $index= int(rand() * $#items);
	if (defined $seen_this_time{$items[$index]}) {
		return &random_tweet($list_ref); #new tweet needed
	}
	$seen_this_time{$items[$index]}++;
	return $items[$index];
}

