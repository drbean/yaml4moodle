package YAML4Moodle::Command::gift;

use lib "lib";

use YAML4Moodle -command;
use strict;
use warnings;
use YAML::XS qw/Dump LoadFile DumpFile/;
use IO::All;

sub abstract { "Convert drbean's YAML quiz questions to Moodle gift format" }
sub description { "Convert drbean's YAML quiz questions to Moodle gift format" }

sub usage_desc { "yaml4moodle gift -c news -t people -s kiss -q jigsaw -f 0" }

sub opt_spec  {
        return (
                ["c=s", "course"]
                , ["t=s", "topic"]
                , ["s=s", "story"]
                , ["q=s", "quiz"]
                , ["f=s", "form"]
	);
}


sub execute {
	my ($self, $opt, $args) = @_;

	my ($course, $topic, $story, $quiz, $form) = @$opt{qw/c t s q f/};

	my $yaml = LoadFile "/home/$ENV{USER}/curriculum/$opt->{c}/$opt->{t}/cards.yaml";

	my @story;
	if ( $story eq 'all' ) {
		delete $yaml->{genre};
		@story = keys %$yaml;
	}
	else { @story = $story; }
	my $gift = "// Auto generated for the '$course' course, '$topic' topic, '$story' story, '$quiz' quiz, '$form' form\n\n";
	my $Course = ucfirst $course;

	unless ( $quiz ) {
		my $story_content = $yaml->{$story};
		my @story_keys = keys %$story_content;
		$quiz = shift @story_keys;
	}
	for my $story ( @story ) {
		my @form;
		my $content = $yaml->{$story}->{$quiz};
		if ( $form eq 'all' ) {
			@form = keys %$content;
		}
		else { @form = $form }
		if ( $quiz eq "jigsaw" ) {
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
		elsif ( $quiz eq "match" ) {
			for my $form ( @form ) {
				my $identifier = $content->{$form}->{identifier};
				$gift .= "// identifier: $identifier\n";
				$gift .= "\n";
				my $n = "00";
				my $pairs = $content->{$form}->{pair};
				my $prefix = substr $pairs->[0]->[1], 0, 15;
				$gift .= ":: $story $quiz $form  Qn $n: $prefix :: Match. {\n";
				for my $pair ( @$pairs ) {
					++$n;
					my $prompt = $pair->[0];
					my $answer = $pair->[1];
					$gift .= "\t=$prompt -> $answer\n";
				}
				$gift .= "}\n\n";
			}
		}
		elsif ( $quiz eq "scramble" ) {
			for my $form ( @form ) {
				my $sentences = $content->{$form}->{sentence};
				$gift .= "// identifier: $content->{$form}->{identifier}\n";
				$gift .= "\n";
				my $n = "00";
				for my $sentence ( @$sentences ) {
					++$n;
					my $prefix = substr $sentence, 0, 15;
					$gift .= ":: $story $form  Qn $n: $prefix :: Unscramble. {\n";
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
