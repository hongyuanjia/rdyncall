#import  <Foundation/NSAutoreleasePool.h>
#import  <AppKit/NSApplication.h>
NSAutoreleasePool* pool;

#ifdef __cplusplus
extern "C" {
#endif
  void CocoaInit();
  void CocoaQuit();
#ifdef __cplusplus
}
#endif

void CocoaInit()
{
  [[NSAutoreleasePool alloc] init];
  NSApplicationLoad();
}

void CocoaQuit()
{
  [pool drain]; 
}

