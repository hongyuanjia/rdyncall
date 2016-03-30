#include "org_dyncall_DC.h"
#include "dyncall.h"
#include "dynload.h"

jlong JNICALL Java_org_dyncall_DC_newCallVM(JNIEnv *pEnv, jclass clazz, jint size)
{
	return (jlong)dcNewCallVM(size);
//@@@ free
}

jlong JNICALL Java_org_dyncall_DC_load(JNIEnv *pEnv, jclass clazz, jstring s)
{
	return (jlong)dlLoadLibrary((const char*)s);
//@@@ free
}

jlong JNICALL Java_org_dyncall_DC_find(JNIEnv *pEnv, jclass clazz, jlong libhandle, jstring s)
{
	return (jlong)dlFindSymbol((DLLib*)libhandle, (const char*)s);
}

//jint JNICALL Java_org_dyncall_DC_symsCount(JNIEnv *pEnv, jclass clazz, jlong symshandle)
//{
//	return dlSymsCount((DLSyms*)symshandle);
//}

//jstring JNICALL Java_org_dyncall_DC_symsName(JNIEnv *pEnv, jclass clazz, jlong symshandle, jint i)
//{
//	return dlSymsName((DLSyms*)symshandle, i);
//}

void JNICALL Java_org_dyncall_DC_mode(JNIEnv *pEnv, jclass clazz, jlong vm, jint i)
{
	dcMode((DCCallVM*)vm, i);
}

void JNICALL Java_org_dyncall_DC_reset(JNIEnv *pEnv, jclass clazz, jlong vm)
{
	dcReset((DCCallVM*)vm);
}

void JNICALL Java_org_dyncall_DC_argBool(JNIEnv *pEnv, jclass clazz, jlong vm, jboolean b)
{
	dcArgBool((DCCallVM*)vm, b);
}

void JNICALL Java_org_dyncall_DC_argChar(JNIEnv *pEnv, jclass clazz, jlong vm, jbyte b)
{
	dcArgChar((DCCallVM*)vm, b);
}

void JNICALL Java_org_dyncall_DC_argShort(JNIEnv *pEnv, jclass clazz, jlong vm, jshort s)
{
	dcArgShort((DCCallVM*)vm, s);
}

void JNICALL Java_org_dyncall_DC_argInt(JNIEnv *pEnv, jclass clazz, jlong vm, jint i)
{
	dcArgInt((DCCallVM*)vm, i);
}

void JNICALL Java_org_dyncall_DC_argLong(JNIEnv *pEnv, jclass clazz, jlong vm, jlong l)
{
	dcArgLong((DCCallVM*)vm, l);
}

void JNICALL Java_org_dyncall_DC_argLongLong(JNIEnv *pEnv, jclass clazz, jlong vm, jlong l)
{
	dcArgLongLong((DCCallVM*)vm, l);
}

void JNICALL Java_org_dyncall_DC_argFloat(JNIEnv *pEnv, jclass clazz, jlong vm, jfloat f)
{
	dcArgFloat((DCCallVM*)vm, f);	
}

void JNICALL Java_org_dyncall_DC_argDouble(JNIEnv *pEnv, jclass clazz, jlong vm, jdouble d)
{
	dcArgDouble((DCCallVM*)vm, d);	
}

void JNICALL Java_org_dyncall_DC_argPointer__JJ(JNIEnv *pEnv, jclass clazz, jlong vm, jlong l)
{
	dcArgPointer((DCCallVM*)vm, (DCpointer)l);
}

void JNICALL Java_org_dyncall_DC_argPointer__JLjava_lang_Object_2(JNIEnv *pEnv, jclass clazz, jlong vm, jobject o)
{
	dcArgPointer((DCCallVM*)vm, (DCpointer)o);
}

void JNICALL Java_org_dyncall_DC_argString(JNIEnv *pEnv, jclass clazz, jlong vm, jstring s)
{
	dcArgPointer((DCCallVM*)vm, (DCpointer)s);
}

void JNICALL Java_org_dyncall_DC_callVoid (JNIEnv *pEnv, jclass clazz, jlong vm, jlong target)
{
	dcCallVoid((DCCallVM*)vm, (DCpointer)target);
}

jboolean JNICALL Java_org_dyncall_DC_callBool(JNIEnv *pEnv, jclass clazz, jlong vm, jlong target)
{
	return dcCallBool((DCCallVM*)vm, (DCpointer)target);
}

jbyte JNICALL Java_org_dyncall_DC_callChar(JNIEnv *pEnv, jclass clazz, jlong vm, jlong target)
{
	return dcCallChar((DCCallVM*)vm, (DCpointer)target);
}

jshort JNICALL Java_org_dyncall_DC_callShort(JNIEnv *pEnv, jclass clazz, jlong vm, jlong target)
{
	return dcCallShort((DCCallVM*)vm, (DCpointer)target);
}

jint JNICALL Java_org_dyncall_DC_callInt(JNIEnv *pEnv, jclass clazz, jlong vm, jlong target)
{
	return dcCallInt((DCCallVM*)vm, (DCpointer)target);
}

jlong JNICALL Java_org_dyncall_DC_callLong(JNIEnv *pEnv, jclass clazz, jlong vm, jlong target)
{
	return dcCallLong((DCCallVM*)vm, (DCpointer)target);
}

jlong JNICALL Java_org_dyncall_DC_callLongLong(JNIEnv *pEnv, jclass clazz, jlong vm, jlong target)
{
	return dcCallLongLong((DCCallVM*)vm, (DCpointer)target);
}

jfloat JNICALL Java_org_dyncall_DC_callFloat(JNIEnv *pEnv, jclass clazz, jlong vm, jlong target)
{
	return dcCallFloat((DCCallVM*)vm, (DCpointer)target);
}

jdouble JNICALL Java_org_dyncall_DC_callDouble(JNIEnv *pEnv, jclass clazz, jlong vm, jlong target)
{
	return dcCallDouble((DCCallVM*)vm, (DCpointer)target);
}

jlong JNICALL Java_org_dyncall_DC_callPointer(JNIEnv *pEnv, jclass clazz, jlong vm, jlong target)
{
	return (jlong)dcCallPointer((DCCallVM*)vm, (DCpointer)target);
}

jstring JNICALL Java_org_dyncall_DC_callString(JNIEnv *pEnv, jclass clazz, jlong vm, jlong target)
{
	return dcCallPointer((DCCallVM*)vm, (DCpointer)target);
}

jint JNICALL Java_org_dyncall_DC_getError(JNIEnv *pEnv, jclass clazz, jlong vm)
{
	return dcGetError((DCCallVM*)vm);
}

