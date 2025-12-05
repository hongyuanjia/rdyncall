

dynbind("SDL_net", "
SDLNet_AddSocket(*<_SDLNet_SocketSet>*<SDLNet_GenericSocket_>)i;
SDLNet_AllocPacket(i)*<UDPpacket>;
SDLNet_AllocPacketV(ii)**<UDPpacket>;
SDLNet_AllocSocketSet(i)*<_SDLNet_SocketSet>;
SDLNet_CheckSockets(*<_SDLNet_SocketSet>I)i;
SDLNet_DelSocket(*<_SDLNet_SocketSet>*<SDLNet_GenericSocket_>)i;
SDLNet_FreePacket(*<UDPpacket>)v;
SDLNet_FreePacketV(**<UDPpacket>)v;
SDLNet_FreeSocketSet(*<_SDLNet_SocketSet>)v;
SDLNet_Init()i;
SDLNet_Linked_Version()*<SDL_version>;
SDLNet_Quit()v;
SDLNet_Read16(*v)S;
SDLNet_Read32(*v)I;
SDLNet_ResizePacket(*<UDPpacket>i)i;
SDLNet_ResolveHost(*<IPaddress>*cS)i;
SDLNet_ResolveIP(*<IPaddress>)*c;
SDLNet_TCP_Accept(*<_TCPsocket>)*<_TCPsocket>;
SDLNet_TCP_Close(*<_TCPsocket>)v;
SDLNet_TCP_GetPeerAddress(*<_TCPsocket>)*<IPaddress>;
SDLNet_TCP_Open(*<IPaddress>)*<_TCPsocket>;
SDLNet_TCP_Recv(*<_TCPsocket>*vi)i;
SDLNet_TCP_Send(*<_TCPsocket>*vi)i;
SDLNet_UDP_Bind(*<_UDPsocket>i*<IPaddress>)i;
SDLNet_UDP_Close(*<_UDPsocket>)v;
SDLNet_UDP_GetPeerAddress(*<_UDPsocket>i)*<IPaddress>;
SDLNet_UDP_Open(S)*<_UDPsocket>;
SDLNet_UDP_Recv(*<_UDPsocket>*<UDPpacket>)i;
SDLNet_UDP_RecvV(*<_UDPsocket>**<UDPpacket>)i;
SDLNet_UDP_Send(*<_UDPsocket>i*<UDPpacket>)i;
SDLNet_UDP_SendV(*<_UDPsocket>**<UDPpacket>i)i;
SDLNet_UDP_Unbind(*<_UDPsocket>i)v;
SDLNet_Write16(S*v)v;
SDLNet_Write32(I*v)v;
")
cstruct("
IPaddress{IS}host port ;
SDLNet_GenericSocket_{i}ready ;
UDPpacket{i*Ciii<IPaddress>}channel data len maxlen status address ;
")
INADDR_ANY=0x00000000
INADDR_BROADCAST=0xFFFFFFFF
INADDR_NONE=0xFFFFFFFF
SDLNET_MAX_UDPADDRESSES=4
SDLNET_MAX_UDPCHANNELS=32
#SDLNet_GetError=SDL_GetError
#SDLNet_SetError=SDL_SetError

