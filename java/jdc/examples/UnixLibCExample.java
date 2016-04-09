import org.dyncall.DC;

// This example tries to make use of each call in the binding.
class UnixLibCExample
{
   	public static void main(String args[])
   	{
		long lib = DC.loadLibrary("/usr/lib/libc.so");
   		System.out.format("libc.so handle: %x\n", lib);

		long f0 = DC.find(lib, "strlen");
   		System.out.format("found strlen at: %x\n", f0);

		long f1 = DC.find(lib, "strstr");
   		System.out.format("found strstr at: %x\n", f1);

		long f2 = DC.find(lib, "strncmp");
   		System.out.format("found strncmp at: %x\n", f2);

		long vm = DC.newCallVM(4096);
		DC.reset(vm);
   		System.out.format("dcGetError() = %d\n", DC.getError(vm));
		DC.mode(vm, 1234567); // bogus mode, should set error
   		System.out.format("dcGetError() = %d (after trying to set bogus mode)\n", DC.getError(vm));
		DC.mode(vm, DC.C_DEFAULT); // good mode, should clear error
   		System.out.format("dcGetError() = %d (after setting valid mode)\n", DC.getError(vm));

		// String param.
		DC.argString(vm, "This is a Java string of 33 chars");
		int r0 = DC.callInt(vm, f0);
   		System.out.format("strlen(\"This is a Java string of 33 chars\") = %d\n", r0);

		// String param and string/pointer return.
		DC.reset(vm);
		DC.argString(vm, "This is a Java string");
		DC.argString(vm, "Java");
		String r1 = DC.callString(vm, f1); // will return a copy of the output string, not like a pointer in C
   		System.out.format("strlen(\"This is a Java string\", \"Java\") = %s\n", r1);
		long r1l = DC.callPointer(vm, f1); // test returning the pointer as long
   		System.out.format("strlen(\"This is a Java string\", \"Java\") = 0x%x (returned pointer, pointless here, but serves as example)\n", r1l);

		DC.reset(vm);
		DC.argString(vm, "This is a Java string");
		DC.argString(vm, "This is");
		DC.argInt(vm, 6);
		int r2 = DC.callInt(vm, f2);
   		System.out.format("strlen(\"This is a Java string\", \"This is\", 6) = %d\n", r2);
		DC.reset(vm);
		DC.argString(vm, "This is a Java string");
		DC.argString(vm, "This is");
		DC.argInt(vm, 8);
		r2 = DC.callInt(vm, f2);
   		System.out.format("strlen(\"This is a Java string\", \"This is\", 8) = %d\n", r2);

		//DC.reset(vm);
		//DC.argDouble(vm,  2.);
		//DC.argDouble(vm, 10.);
		//double r1 = DC.callDouble(vm, f1);
   		//System.out.format("pow(2., 10.) = %f\n", r1);

		// Done, cleanup.
		DC.freeCallVM(vm);
		DC.freeLibrary(lib);
	}
}

