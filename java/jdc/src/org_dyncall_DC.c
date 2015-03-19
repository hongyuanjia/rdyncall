#include "org_dyncall_DC.h"
#include "../../../../dyncall/dyncall.h"
jlong JNICALL Java_org_dyncall_DC_newCallVM
  (JNIEnv *pEnv, jclass clazz, jint mode, jint size)
{
	return (jlong) dcNewCallVM(mode,size);
}

void JNICALL Java_org_dyncall_DC_reset (JNIEnv *, jclass, jlong vm)
{
	DCCallVM* vm = (DCCallVM*) in_vm;
	dcReset(vm);
}

void JNICALL Java_org_dyncall_DC_argBool(JNIEnv *, jclass, jlong vm, jboolean b)
{
	DCCallVM* vm = (DCCallVM*) in_vm;
	dcPushBool(vm,b);
}

void JNICALL Java_org_dyncall_DC_argByte (JNIEnv *, jclass, jlong in_vm, jbyte b)
{
	DCCallVM* vm = (DCCallVM*) in_vm;
	dcPushChar(vm,b);
}
void JNICALL Java_org_dyncall_DC_argShort(JNIEnv *, jclass, jlong in_vm, jshort s)
{
	DCCallVM* vm = (DCCallVM*) in_vm;
	dcPushShort(vm,s);
}

void JNICALL Java_org_dyncall_DC_argInt(JNIEnv *, jclass, jlong in_vm, jint i)
{
	DCCallVM* vm = (DCCallVM*) in_vm;
	dcPushInt(vm,i);

}
void JNICALL Java_org_dyncall_DC_argLong (JNIEnv *, jclass, jlong in_vm, jlong l)
{
	DCCallVM* vm = (DCCallVM*) in_vm;
	dcPushLong(vm,l);
}

void JNICALL Java_org_dyncall_DC_argChar(JNIEnv *, jclass, jlong in_vm, jchar c)
{
	DCCallVM* vm = (DCCallVM*) in_vm;
	dcPushChar(vm,c);	
}

void JNICALL Java_org_dyncall_DC_argFloat(JNIEnv *, jclass, jlong in_vm, jfloat f)
{
	DCCallVM* vm = (DCCallVM*) in_vm;
	dcPushFloat(vm,f);	
}

void JNICALL Java_org_dyncall_DC_argDouble(JNIEnv *, jclass, jlong in_vm, jdouble d)
{
	DCCallVM* vm = (DCCallVM*) in_vm;
	dcPushDouble(vm,d);		
}

void JNICALL Java_org_dyncall_DC_argPointer__JJ(JNIEnv *, jclass, jlong in_vm, jlong l)
{
	DCCallVM* vm = (DCCallVM*) in_vm;
	dcPushPointer(vm, (DCpointer) l );			
}

void JNICALL Java_org_dyncall_DC_argPointer__JLjava_lang_Object_2(JNIEnv *, jclass, jlong in_vm, jobject o)
{
	DCCallVM* vm = (DCCallVM*) in_vm;
	dcPushPointer(vm, (DCpointer) o );			
}

void JNICALL Java_org_dyncall_DC_argString(JNIEnv *, jclass, jlong, jstring)
{
	DCCallVM* vm = (DCCallVM*) in_vm;
	dcPushPointer(vm, (DCpointer) o );	
}

void JNICALL Java_org_dyncall_DC_callVoid (JNIEnv *, jclass, jlong in_vm, jlong in_target)
{
	DCCallVM* vm = (DCCallVM*) in_vm;
	dcCallVoid(vm, (DCpointer) target)
}

/*
 * Class:     org_dyncall_DC
 * Method:    callBoolean
 * Signature: (JJ)Z
 */
jboolean JNICALL Java_org_dyncall_DC_callBoolean(JNIEnv *, jclass, jlong in_vm, jlong target)
{
	DCCallVM* vm = (DCCallVM*) in_vm;
	dcCallBoolean(vm, (DCpointer) target)
}

/*
 * Class:     org_dyncall_DC
 * Method:    callInt
 * Signature: (JJ)I
 */
JNIEXPORT jint JNICALL Java_org_dyncall_DC_callInt
  (JNIEnv *, jclass, jlong, jlong);

/*
 * Class:     org_dyncall_DC
 * Method:    callLong
 * Signature: (JJ)J
 */
JNIEXPORT jlong JNICALL Java_org_dyncall_DC_callLong
  (JNIEnv *, jclass, jlong, jlong);

