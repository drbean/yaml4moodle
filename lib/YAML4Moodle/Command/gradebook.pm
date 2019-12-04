package YAML4Moodle::Command::gradebook;

use lib "lib";

use YAML4Moodle -command;
use strict;
use warnings;
use YAML qw/Dump LoadFile DumpFile/;
use IO::All;
use Cwd;
use File::Basename;


sub abstract { "import-ready csv file from beancan-name yaml file" }
sub description { "munges in-class evaluated yaml beancan-name file to moodle-ready cvs gradebook file. Do not use if not name-keyed. For manually-created gradeitem, 'Quiz: ' may not be prepended." }

sub usage_desc { 'yaml4moodle gradebook -l BMA0034 -t "Saying something about letters" -w 3' }

sub opt_spec  {
        return (
                ["l=s", "league"]
                , ["t=s", "topic"]
                , ["w=s", "week"]
	);
}


sub execute {
	my ($self, $opt, $args) = @_;

	my ($directory, $topic, $week) = @$opt{qw/l t w/};
	$directory = $directory? $directory : basename( getcwd );
	die "description topic '$topic'?" unless $topic;
	die "description form '$week'?" unless defined $week;

	my $semester = $ENV{SEMESTER};

	use Grades;

	my $league = League->new( leagues => "/home/drbean/$semester", id => $directory );
	my $members = $league->members;
	my %name_list = map { $_->{name} => $_ } @$members;

	my $beancan_hash = LoadFile "/home/drbean/$semester/$directory/classwork/$week.yaml";
	my %score;
	@score{ keys %$_ } = values %$_ for values %$beancan_hash;
	## case of $week.yaml is not beancan-keyed, but player id-keyed
	# @score{ keys %$beancan_hash } = values %$beancan_hash;
	my %grade;
	$grade{$name_list{$_}->{id} } = $score{$_} for keys %score;

	my $io = io "classwork/$week.csv";
	# if manual, perhaps 'Quiz:' not prepended
	$io->print( '"ID number","Quiz: ' . $topic . '"' . "\n" );
	$io->append( "$_,$grade{$_}\n") for keys %grade;
	$io->autoflush;
}

1;
