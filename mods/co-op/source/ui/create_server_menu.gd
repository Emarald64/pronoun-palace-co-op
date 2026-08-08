extends MenuPanel

@export var lobby:MenuPanel
#var upnp:UPNP

func host_pressed():
	print("starting enet hosting")
	var peer=ENetMultiplayerPeer.new()
	var server_error=peer.create_server(%Port.value,%MaxPlayers.value)
	if server_error==Error.OK:
		print("server created ok")
		if %ForwardPort.button_pressed:
			var upnp_error=Game.upnp.add_port_mapping(%Port.value,0,"Pronoun Palace coop")
			if upnp_error!=UPNP.UPNPResult.UPNP_RESULT_SUCCESS:
				push_error("UPnP port map failure: ",upnp_error)
			else:
				print("upnp port map success")
		menu_controller.set_menu(lobby)
		multiplayer.multiplayer_peer=peer
		if %Name.text.is_empty():
			Game.player_info.name="Host"
		else:
			Game.player_info.name=%Name.text
		Game.players[1]=Game.player_info
		Game.player_connected.emit(1,Game.player_info)
	else:
		push_error("server creation error:", server_error)
		%Header.text=error_string(server_error)

func enable_upnp():
	Game.upnp=UPNP.new()
	var err=Game.upnp.discover()
	if err==UPNP.UPNP_RESULT_SUCCESS:
		print("UPnP discovery ok")
		%"UPnP Option".hide()
		%"UPnP Stuff".show()
	else:
		push_error("UPnP discovery error ",err)

func show_ip():
	%IP.text=Game.upnp.query_external_address()
	%ShowIPButton.hide()
	%IP.show()
