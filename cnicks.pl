sub my_hook_command_run_cb {
	$h_command_run = weechat::hook_command_run( "/input complete*", "my_command_run_cb", "" );
}

sub my_command_run_cb {
	my $buffer = $_[1];
	my $command_run = $_[2];
	weechat::command( $buffer, "$command_run" );
	$buffer_input_str = weechat::buffer_get_string( $buffer, "input" );
	my $last_word = (split m/\s+/, $buffer_input_str)[-1];
	my $buffer_full_name = weechat::buffer_get_string( $buffer, "full_name" );
	my $name = weechat::buffer_get_string( $buffer, "name" );
	$name =~ /^(.*)\.(#.*)$/;
	my $server = $1;
	my $channel = $2;
	if ( $last_word eq $channel ) {
		weechat::print ( $buffer, $channel );
	} else {
		$infolist_nicks = weechat::infolist_get( "irc_nick", "", "$server,$channel" );
		while ( weechat::infolist_next( $infolist_nicks ) ) {
			my $nick = weechat::infolist_string ( $infolist_nicks, "name" );
			if ( $nick eq $last_word ) {
				word_is_nick( $buffer, $nick );
			}
		}
	}
}

sub word_is_nick {
	my ( $buffer, $nick ) = @_;
	my $new_nick = "$symbol{'left'}" . "\cC8,12$nick" . "$symbol{'right'}";
	$buffer_input_str =~ s/\b$nick\b( *)$/$new_nick/;
	weechat::buffer_set ( $buffer, "input", "$buffer_input_str " );
	my $length = weechat::buffer_get_integer( $buffer, "input_length" );
	weechat::buffer_set ( $buffer, "input_pos", $length );
}

weechat::register ( "cnicks", "nashgul", "0.1", "gnu", "complete nicks with colors and symbols", "", "" );

$own_nick{'hispano'} = "z0idberg";
$own_nick{'freenode'} = "nashgul";

$symbol{'left'} = "\cB\cC5,12[[ ";
$symbol{'right'} = "\cC5,12 ]]\cC\cB";

my_hook_command_run_cb;
