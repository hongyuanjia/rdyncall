

dynbind( c("pcap","pcap.so.0.8") , "
pcap_activate(*<pcap>)i;
pcap_breakloop(*<pcap>)v;
pcap_can_set_rfmon(*<pcap>)i;
pcap_close(*<pcap>)v;
pcap_compile(*<pcap>*<bpf_program>*ciI)i;
pcap_compile_nopcap(ii*<bpf_program>*ciI)i;
pcap_create(*c*c)*<pcap>;
pcap_datalink(*<pcap>)i;
pcap_datalink_ext(*<pcap>)i;
pcap_datalink_name_to_val(*c)i;
pcap_datalink_val_to_description(i)*c;
pcap_datalink_val_to_name(i)*c;
pcap_dispatch(*<pcap>i*p*C)i;
pcap_dump(*C*<pcap_pkthdr>*C)v;
pcap_dump_close(*<pcap_dumper>)v;
pcap_dump_file(*<pcap_dumper>)*<__sFILE>;
pcap_dump_flush(*<pcap_dumper>)i;
pcap_dump_fopen(*<pcap>*<__sFILE>)*<pcap_dumper>;
pcap_dump_ftell(*<pcap_dumper>)j;
pcap_dump_open(*<pcap>*c)*<pcap_dumper>;
pcap_file(*<pcap>)*<__sFILE>;
pcap_fileno(*<pcap>)i;
pcap_findalldevs(**<pcap_if>*c)i;
pcap_fopen_offline(*<__sFILE>*c)*<pcap>;
pcap_fopen_offline_with_tstamp_precision(*<__sFILE>I*c)*<pcap>;
pcap_free_datalinks(*i)v;
pcap_free_tstamp_types(*i)v;
pcap_freealldevs(*<pcap_if>)v;
pcap_freecode(*<bpf_program>)v;
pcap_get_selectable_fd(*<pcap>)i;
pcap_get_tstamp_precision(*<pcap>)i;
pcap_geterr(*<pcap>)*c;
pcap_getnonblock(*<pcap>*c)i;
pcap_inject(*<pcap>*vJ)i;
pcap_is_swapped(*<pcap>)i;
pcap_lib_version()*c;
pcap_list_datalinks(*<pcap>**i)i;
pcap_list_tstamp_types(*<pcap>**i)i;
pcap_lookupdev(*c)*c;
pcap_lookupnet(*c*I*I*c)i;
pcap_loop(*<pcap>i*p*C)i;
pcap_major_version(*<pcap>)i;
pcap_minor_version(*<pcap>)i;
pcap_next(*<pcap>*<pcap_pkthdr>)*C;
pcap_next_ex(*<pcap>**<pcap_pkthdr>**C)i;
pcap_offline_filter(*<bpf_program>*<pcap_pkthdr>*C)i;
pcap_open_dead(ii)*<pcap>;
pcap_open_dead_with_tstamp_precision(iiI)*<pcap>;
pcap_open_live(*ciii*c)*<pcap>;
pcap_open_offline(*c*c)*<pcap>;
pcap_open_offline_with_tstamp_precision(*cI*c)*<pcap>;
pcap_perror(*<pcap>*c)v;
pcap_sendpacket(*<pcap>*Ci)i;
pcap_set_buffer_size(*<pcap>i)i;
pcap_set_datalink(*<pcap>i)i;
pcap_set_immediate_mode(*<pcap>i)i;
pcap_set_promisc(*<pcap>i)i;
pcap_set_rfmon(*<pcap>i)i;
pcap_set_snaplen(*<pcap>i)i;
pcap_set_timeout(*<pcap>i)i;
pcap_set_tstamp_precision(*<pcap>i)i;
pcap_set_tstamp_type(*<pcap>i)i;
pcap_setdirection(*<pcap>i)i;
pcap_setfilter(*<pcap>*<bpf_program>)i;
pcap_setnonblock(*<pcap>i*c)i;
pcap_snapshot(*<pcap>)i;
pcap_stats(*<pcap>*<pcap_stat>)i;
pcap_statustostr(i)*c;
pcap_strerror(i)*c;
pcap_tstamp_type_name_to_val(*c)i;
pcap_tstamp_type_val_to_description(i)*c;
pcap_tstamp_type_val_to_name(i)*c;
")
cstruct("
bpf_insn{SCCI}code jt jf k ;
bpf_program{I*<bpf_insn>}bf_len bf_insns ;
pcap_addr{*<pcap_addr>*<sockaddr>*<sockaddr>*<sockaddr>*<sockaddr>}next addr netmask broadaddr dstaddr ;
pcap_dumper{};
pcap_file_header{ISSiIII}magic version_major version_minor thiszone sigfigs snaplen linktype ;
pcap_if{*<pcap_if>*c*c*<pcap_addr>I}next name description addresses flags ;
pcap_pkthdr{<timeval>II}ts caplen len ;
pcap_stat{III}ps_recv ps_drop ps_ifdrop ;
pcap{};
sockaddr{};
timeval{ji}tv_sec tv_usec ;
")
PCAP_D_IN=1;
PCAP_D_INOUT=0;
PCAP_D_OUT=2;
PCAP_ERRBUF_SIZE=256
PCAP_ERROR=-1
PCAP_ERROR_ACTIVATED=-4
PCAP_ERROR_BREAK=-2
PCAP_ERROR_CANTSET_TSTAMP_TYPE=-10
PCAP_ERROR_IFACE_NOT_UP=-9
PCAP_ERROR_NOT_ACTIVATED=-3
PCAP_ERROR_NOT_RFMON=-7
PCAP_ERROR_NO_SUCH_DEVICE=-5
PCAP_ERROR_PERM_DENIED=-8
PCAP_ERROR_PROMISC_PERM_DENIED=-11
PCAP_ERROR_RFMON_NOTSUP=-6
PCAP_ERROR_TSTAMP_PRECISION_NOTSUP=-12
PCAP_IF_LOOPBACK=0x00000001
PCAP_NETMASK_UNKNOWN=0xffffffff
PCAP_TSTAMP_ADAPTER=3
PCAP_TSTAMP_ADAPTER_UNSYNCED=4
PCAP_TSTAMP_HOST=0
PCAP_TSTAMP_HOST_HIPREC=2
PCAP_TSTAMP_HOST_LOWPREC=1
PCAP_TSTAMP_PRECISION_MICRO=0
PCAP_TSTAMP_PRECISION_NANO=1
PCAP_VERSION_MAJOR=2
PCAP_VERSION_MINOR=4
PCAP_WARNING=1
PCAP_WARNING_PROMISC_NOTSUP=2
PCAP_WARNING_TSTAMP_TYPE_NOTSUP=3

