#include "org_dyncall_DC.h"
#include "dyncall.h"

jlong JNICALL Java_org_dyncall_DC_newCallVM(JNIEnv *pEnv, jclass clazz, jint mode, jint size)
{
	return (jlong)dcNewCallVM(mode, size);
//@@@ free
}

jlong JNICALL Java_org_dyncall_DC_load(JNIEnv *, jclass, jstring s)
{
	return dlLoadLibrary((const char*)s);
//@@@ free
}

jlong JNICALL Java_org_dyncall_DC_find(JNIEnv *, jclass, jlong libhandle, jstring s)
{
	return dlFindSymbol((DLLib*)libhandle, (const char*)s);
}

//jint JNICALL Java_org_dyncall_DC_symsCount(JNIEnv *, jclass, jlong symshandle)
//{
//	return dlSymsCount((DLSyms*)symshandle);
//}

//jstring JNICALL Java_org_dyncall_DC_symsName(JNIEnv *, jclass, jlong symshandle, jint i)
//{
//	return dlSymsName((DLSyms*)symshandle, i);
//}

void JNICALL Java_org_dyncall_DC_mode(JNIEnv *, jclass, jlong in_vm, jint i)
{
	dcMode((DCCallVM*)in_vm, i);
}

void JNICALL Java_org_dyncall_DC_reset(JNIEnv *, jclass, jlong in_vm)
{
	dcReset((DCCallVM*)in_vm);
}

void JNICALL Java_org_dyncall_DC_argBool(JNIEnv *, jclass, jlong in_vm, jboolean b)
{
	dcPushBool((DCCallVM*)in_vm, b);
}

void JNICALL Java_org_dyncall_DC_argChar(JNIEnv *, jclass, jlong in_vm, jbyte b)
{
	dcPushChar((DCCallVM*)in_vm, b);
}

void JNICALL Java_org_dyncall_DC_argShort(JNIEnv *, jclass, jlong in_vm, jshort s)
{
	dcPushShort((DCCallVM*)in_vm, s);
}

void JNICALL Java_org_dyncall_DC_argInt(JNIEnv *, jclass, jlong in_vm, jint i)
{
	dcPushInt((DCCallVM*)in_vm, i);
}

void JNICALL Java_org_dyncall_DC_argLong(JNIEnv *, jclass, jlong in_vm, jlong l)
{
	dcPushLong((DCCallVM*)in_vm, l);
}

void JNICALL Java_org_dyncall_DC_argLongLong(JNIEnv *, jclass, jlong in_vm, jlong l)
{
	dcPushLongLong((DCCallVM*)in_vm, l);
}

void JNICALL Java_org_dyncall_DC_argFloat(JNIEnv *, jclass, jlong in_vm, jfloat f)
{
	dcPushFloat((DCCallVM*)in_vm, f);	
}

void JNICALL Java_org_dyncall_DC_argDouble(JNIEnv *, jclass, jlong in_vm, jdouble d)
{
	dcPushDouble((DCCallVM*)in_vm, d);	
}

void JNICALL Java_org_dyncall_DC_argPointer__JJ(JNIEnv *, jclass, jlong in_vm, jlong l)
{
	dcPushPointer((DCCallVM*)in_vm, (DCpointer)l);
}

void JNICALL Java_org_dyncall_DC_argPointer__JLjava_lang_Object_2(JNIEnv *, jclass, jlong in_vm, jobject o)
{
	dcPushPointer((DCCallVM*)in_vm, (DCpointer)o);
}

void JNICALL Java_org_dyncall_DC_argString(JNIEnv *, jclass, jlong in_vm, jstring s)
{
	dcPushPointer((DCCallVM*)in_vm, (DCpointer)s);
}

void JNICALL Java_org_dyncall_DC_callVoid (JNIEnv *, jclass, jlong in_vm, jlong in_target)
{
	dcCallVoid((DCCallVM*)in_vm, (DCpointer)target)
}

jboolean JNICALL Java_org_dyncall_DC_callBool(JNIEnv *, jclass, jlong in_vm, jlong target)
{
	return dcCallBool((DCCallVM*)in_vm, (DCpointer)target)
}

jbyte JNICALL Java_org_dyncall_DC_callChar(JNIEnv *, jclass, jlong in_vm, jlong target)
{
	return dcCallChar((DCCallVM*)in_vm, (DCpointer)target)
}

jshort JNICALL Java_org_dyncall_DC_callShort(JNIEnv *, jclass, jlong in_vm, jlong target)
{
	return dcCallShort((DCCallVM*)in_vm, (DCpointer)target)
}

jint JNICALL Java_org_dyncall_DC_callInt(JNIEnv *, jclass, jlong in_vm, jlong target)
{
	return dcCallInt((DCCallVM*)in_vm, (DCpointer)target)
}

jlong JNICALL Java_org_dyncall_DC_callLong(JNIEnv *, jclass, jlong in_vm, jlong target)
{
	return dcCallLong((DCCallVM*)in_vm, (DCpointer)target)
}

jlong JNICALL Java_org_dyncall_DC_callLongLong(JNIEnv *, jclass, jlong in_vm, jlong target)
{
	return dcCallLongLong((DCCallVM*)in_vm, (DCpointer)target)
}

jfloat JNICALL Java_org_dyncall_DC_callFloat(JNIEnv *, jclass, jlong in_vm, jlong target)
{
	return dcCallFloat((DCCallVM*)in_vm, (DCpointer)target)
}

jdouble JNICALL Java_org_dyncall_DC_callDouble(JNIEnv *, jclass, jlong in_vm, jlong target)
{
	return dcCallDouble((DCCallVM*)in_vm, (DCpointer)target)
}

jlong JNICALL Java_org_dyncall_DC_callPointer(JNIEnv *, jclass, jlong in_vm, jlong target)
{
	return dcCallPointer((DCCallVM*)in_vm, (DCpointer)target)
}

jstring JNICALL Java_org_dyncall_DC_callString(JNIEnv *, jclass, jlong in_vm, jlong target)
{
	return dcCallPointer((DCCallVM*)in_vm, (DCpointer)target)
}

jint JNICALL Java_org_dyncall_DC_getError(JNIEnv *, jclass, jlong in_vm)
{
	return dcGetError((DCCallVM*)in_vm);
}

