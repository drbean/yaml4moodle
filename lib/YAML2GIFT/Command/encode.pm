package YAML2GIFT::Command::encode;

use lib "lib";

use YAML2GIFT -command;
use strict;
use warnings;
use YAML qw/Dump LoadFile DumpFile/;
use IO::All;

sub abstract { "Convert drbean's YAML quiz questions to Moodle GIFT format" }
sub description { "Convert drbean's YAML quiz questions to Moodle GIFT format" }

sub usage_desc { "yaml2gift encode -c news -t people -s kiss -f 0" }

sub opt_spec  {
        return (
                ["c=s", "course"]
                , ["t=s", "topic"]
                , ["s=s", "story"]
                , ["f=s", "form"]
	);
}


sub execute {
	my ($self, $opt, $args) = @_;

	my ($course, $topic, $story, $form) = @$opt{qw/c t s f/};

	my $yaml = LoadFile "/home/drbean/curriculum/$opt->{c}/$opt->{t}/cards.yaml";

	my @story;
	if ( $story eq 'all' ) {
		delete $yaml->{genre};
		@story = keys %$yaml;
	}
	else { @story = $story; }
	my $gift = "// Auto generated for the '$course' course, '$topic' topic, '$story' story, '$form' form\n\n";
	$gift .= '// $CATEGORY: $cat1$' . "/Default for $course\n\n";
	for my $story ( @story ) {
		my @form;
		if ( $yaml->{$story}->{jigsaw} ) {
			my $content = $yaml->{$story}->{jigsaw};
			if ( $form eq 'all' ) {
				@form = keys %$content;
			}
			else { @form = $form }
			for my $form ( @form ) {
				my $quiz = $content->{$form}->{quiz};

				$gift .= "// identifier: $content->{$form}->{identifier}\n";
				$gift .= "\n";
				my $n = "00";
				for my $item ( @$quiz ) {
					++$n;
					my $question = $item->{question};
					my $answer = $item->{answer};
					my $prefix = substr $question, 0, 15;
					$gift .= ":: $story $form  Qn $n: $prefix :: $question {\n";
					if ( defined $item->{option} ) {
						my $option = $item->{option};
						for my $alternative ( @$option ) {
							if ( $answer eq $alternative ) {
								$gift .= "= $alternative\n";
							}
							else { $gift .= "~ $alternative\n" }
						}
					}
					else { $gift .= uc $answer . "\n"}
					$gift .= "}\n\n";
				}
			}
		}
		elsif ( $yaml->{$story}->{scramble} ) {
			my $content = $yaml->{$story}->{scramble};
			if ( $form eq 'all' ) {
				@form = keys %$content;
			}
			else { @form = $form }
			for my $form ( @form ) {
				my $sentences = $content->{$form}->{sentence};
				$gift .= "// identifier: $content->{$form}->{identifier}\n";
				$gift .= "\n";
				my $n = "00";
				for my $sentence ( @$sentences ) {
					++$n;
					$gift .= ":: $story $form  Qn $n :: Put the following words in order. {\n";
					my @word = split '\s', $sentence;
					my $m = "00";
					for my $word ( @word ) {
						++$m;
						$gift .= "\t=$m -> $word\n"
					}
					$gift .= "}\n\n";
				}
			}
		}
	}
	$gift > io("-");

}

1;
