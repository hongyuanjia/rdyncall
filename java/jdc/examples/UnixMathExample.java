import org.dyncall.DC;

class UnixMathExample
{
   	public static void main(String args[])
   	{
		long lib = DC.loadLibrary("/usr/lib/libm.so");
   		System.out.format("libm.so handle: %x\n", lib);

		long f0 = DC.find(lib, "sqrtf");
   		System.out.format("found sqrtf at: %x\n", f0);

		long f1 = DC.find(lib, "pow");
   		System.out.format("found pow at: %x\n", f1);

		long vm = DC.newCallVM(4096);
		DC.argFloat(vm, 36.f);
		float r0 = DC.callFloat(vm, f0);
   		System.out.format("sqrtf(36.f) = %f\n", r0);

		DC.reset(vm);
		DC.argDouble(vm,  2.);
		DC.argDouble(vm, 10.);
		double r1 = DC.callDouble(vm, f1);
   		System.out.format("pow(2., 10.) = %f\n", r1);

		// Done, cleanup.
		DC.freeCallVM(vm);
		DC.freeLibrary(lib);
	}
}

