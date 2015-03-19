#!/bin/sh
gcc -I../../../dyncall/dyncall shdc.c ../../../dyncall/dyncall/libdyncall_s.a ../../../dyncall/dynload/libdynload_s.a -o ./shdc
