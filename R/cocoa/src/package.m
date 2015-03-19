/** ===========================================================================
 ** R-Package: cocoa
 ** File: coca/src/package.m
 ** Description: R package registry and initialization of NSAutoreleasePool
 **
 ** Copyright (C) 2009 Daniel Adler
 **/
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <stdio.h>
#import  <Foundation/NSAutoreleasePool.h>
#import  <AppKit/NSApplication.h>
NSAutoreleasePool* pool;

void R_init_cocoa(DllInfo* info)
{
  [[NSAutoreleasePool alloc] init];
  NSApplicationLoad();
  // [NSApplication sharedApplication];
  // [NSApp run];
  printf("init\n");

}

void R_unload_cocoa(DllInfo* info)
{
  [pool drain]; 
}

