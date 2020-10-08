package YAML4Moodle::Command::description;

use lib "lib";

# use YAML4Moodle -command;
use strict;
use warnings;
use YAML qw/Dump LoadFile DumpFile/;
# use IO::All;
use XML::DOM;


sub abstract { "Create Moodle description quiz question in xml format on fly" }
sub description { "Markdown text description inserted in multi-question quiz" }

sub usage_desc { 'yaml4moodle description -t $markdown_text -i identifier' }

sub opt_spec  {
        return (
                ["d=s", "questiontext"]
                , ["i=s", "identifier"]
                , ["t=s", "topic"]
                , ["s=s", "story"]
                , ["f=s", "form"]
	);
}


sub execute {
	my ($self, $opt, $args) = @_;

	my ($description, $identifier, $topic, $story, $form) = @$opt{qw/d i t s f/};
	die "description questiontext: '$description'?" unless $description;
	die "description identifier '$identifier'?" unless $identifier;
	die "description topic '$topic'?" unless $topic;
	die "description story '$story'?" unless $story;
	die "description form '$form'?" unless defined $form;

	my $xml = '<?xml version="1.0" encoding="UTF-8"?>';

	$XML::DOM::Parser::KeepCDATA = 1;
	my $q = XML::DOM::Document->createElement("quiz");
	my $cat_qn = XML::DOM::Document->createElement("question");
	$cat_qn->setAttribute("type","category");
	my $cat = XML::DOM::Document->createElement("category");
	my $cat_text = XML::DOM::Document->createElement("text");
	$cat_text->addText("\$cat1\$/top/$topic/$story");
	$cat->appendChild($cat_text);
	$cat_qn->appendChild($cat);
	$q->appendChild($cat_qn);

	my $comment = XML::DOM::Document->createComment
	("identifier: $identifier");
	$q->appendChild( $comment );

	my $prefix = substr $description, 0, 15;
	my $qn = XML::DOM::Document->createElement("question");
	$qn->setAttribute("type","description");
	my $name = XML::DOM::Document->createElement("name");
	my $text = XML::DOM::Document->createElement("text");
	$text->addText("$story $form: $prefix description");
	$name->appendChild( $text);
	$qn->appendChild( $name);

	my $qntext = XML::DOM::Document->createElement("questiontext");
	$qntext->setAttribute("format","markdown");
	$text = XML::DOM::Document->createElement("text");
	my $cdata_text = $description;
	$XML::DOM::Parser::KeepCDATA = 1;
	my $cdata = XML::DOM::Document->createCDATASection( $cdata_text );
	$text->appendChild( $cdata );
	$qntext->appendChild( $text );
	$qn->appendChild( $qntext );
	$q->appendChild($qn);

	$xml .= $q->toString;

	# $xml > io("-");
	return $xml;
}

1;
