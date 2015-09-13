sub init_config {
	$config_file = weechat::config_new ( "cnicks", "my_config_reload_cb", "" ); 
	return if ( ! $config_file );
	my $section = weechat::config_new_section ( $config_file, "config", 0, 0, "", "", "", "", "", "", "", "", "", "" );
	$config{'buffers_blacklist'} = weechat::config_new_option ( $config_file, $section, "buffers_blacklist", "string", 
	"buffers where script do not work, separated by commas. e.g.: freenode.#debian, hispano.#linux", "", 0, 0, "", "", 1, "", "", "load_vars_cb", "", "", "" );
	$config{'left_symbol'} = weechat::config_new_option ( $config_file, $section, "left_symbol", "string", 
	"left_symbol", "", 0, 0, "[[ ", "[[ ", 1, "", "", "load_vars_cb", "", "", "" );
	$config{'right_symbol'} = weechat::config_new_option ( $config_file, $section, "right_symbol", "string",
	"right_symbol",	"", 0, 0, " ]]", " ]]", 1, "", "", "load_vars_cb", "", "", "" );
	$config{'left_color'} = weechat::config_new_option ( $config_file, $section, "left_color", "string", 
	"left_color, e.g.: 5,12 (5 for fg and 12 for bg), 5 (5 for fg, no bg). $color_codes ", "", 0, 0, "5,12", "5,12", 1, "", "", "load_vars_cb", "", "", "" );
	$config{'right_color'} = weechat::config_new_option ( $config_file, $section, "right_color", "string", 
	"right_color, e.g.: 5,12 (5 for fg and 12 for bg), 5 (5 for fg, no bg). $color_codes", "", 0, 0, "5,12", "5,12", 1, "", "", "load_vars_cb", "", "", "" );
	$config{'nick_color'} = weechat::config_new_option ( $config_file, $section, "nick_color", "string", 
	"nick_color, e.g.: 5,12 (5 for fg and 12 for bg), 5 (5 for fg, no bg). $color_codes", "", 0, 0, "8,12", "8,12", 1, "", "", "load_vars_cb", "", "", "" );
}

sub my_config_reload_cb {
	return weechat::config_reload( $config_file );
}

sub config_read {
	return weechat::config_read( $config_file );
}

sub config_write {
	return weechat::config_write( $config_file );
}

sub load_vars_cb {
	foreach $y ( sort keys(%config) ) {
		$pointer = weechat::config_get("cnicks.config.$y");
		$value{$y} = weechat::config_string($pointer);
	}
}

sub my_hook_command_run_cb {
	$h_command_run = weechat::hook_command_run( "/input complete*", "my_command_run_cb", "" );
	$h_command_run_return = weechat::hook_command_run( "/input return", "my_command_run_return_cb", "" );
}

sub my_command_run_cb {
	my $buffer = $_[1];
	my $command_run = $_[2];
	my $input_str = weechat::buffer_get_string( $buffer, "input" );
	return if ( $input_str =~ /^\/.*/ );
	weechat::command( $buffer, "$command_run" );
	$buffer_input_str = weechat::buffer_get_string( $buffer, "input" );
	my $last_word = (split m/\s+/, $buffer_input_str)[-1];
	my $irc_servers_ptr = weechat::infolist_get( "irc_server", "", "" );
	my $j = 0;
	while ( weechat::infolist_next( $irc_servers_ptr ) ) {
		my %own_nick;
		my %server_name;
		$server_name[$j] = weechat::infolist_string ( $irc_servers_ptr, "name" );
		$own_nick[$server_name[$j]] = weechat::infolist_string ( $irc_servers_ptr, "nick" );
		$j++;
	}
	my $name = weechat::buffer_get_string( $buffer, "name" );
	foreach $z (@server_name) {
		if ( $name =~ /^$z.*/ ) {
			$server = $z;
			$name =~ s/^$z\.//;
			$channel = $name;
			last;
		}
	}
	if ( $last_word eq $channel ) {
		# TODO decorate channel word
		word_is_nick ( $buffer, $last_word );
	} else {
		$infolist_nicks = weechat::infolist_get( "irc_nick", "", "$server,$channel" );
		while ( weechat::infolist_next( $infolist_nicks ) ) {
			my $nick = weechat::infolist_string ( $infolist_nicks, "name" );
			if ( $nick eq $last_word ) {
				word_is_nick ( $buffer, $nick );
			}
		}
	}
}

sub word_is_nick {
	my ( $buffer, $nick ) = @_;
	my $new_nick = "@@" . "$nick" . "@@";
	$buffer_input_str =~ s/\b$nick\b( *)$/$new_nick/;
	weechat::buffer_set ( $buffer, "input", "$buffer_input_str " );
	my $length = weechat::buffer_get_integer( $buffer, "input_length" );
	weechat::buffer_set ( $buffer, "input_pos", $length );
}

sub my_command_run_return_cb {
	$string_sent = "";
	my $buffer = $_[1];
	my $final_string = weechat::buffer_get_string( $buffer, "input" );
	$string_sent = weechat::hook_modifier( "input_text_for_buffer", "my_modifier_cb", "" );
}

sub my_modifier_cb {
	my $modifier_ptr = $_[0];
	my $string = $_[3];
	@string = split(/ +/, $string);
	$string = "";
	my $nick = "";
	foreach $x (@string) {
		if ( $x =~ /^(\@\@)(.*)(\@\@)$/ ) {
			$nick = $2;
			$nick = "\cB\cC$value{'left_color'}$value{'left_symbol'}" 
			. "\cC$value{'nick_color'}" . "$nick" 
			. "\cC$value{'right_color'}$value{'right_symbol'}\cC\cB";
			$string = $string . $nick . " ";
		} else {
			$string = $string . "$x" . " ";
		}
	}
	return ( "$string" );
}
	


weechat::register ( "cnicks", "nashgul", "0.1", "gnu", "complete nicks with colors and symbols", "", "" );

$color_codes = "00 - white; 1 - black; 2 - blue; 3 - green; 4 - lightred; 5 - red; 6 - magenta; 7 - brown; 8 - yellow; 9 - lightgreen; 10 - cyan; 11 - lightcyan; 12 - lightblue; 13 - lightmagenta; 14 - darkgray; 15 - gray;";

init_config;
config_read;
load_vars_cb;
my_hook_command_run_cb;
