#define INFILE
	
using System;
namespace Tester
{
	public partial class PartialUser
	{
		public PartialUser ()
		{
		}
		
	 	partial void doPart(String[] args)
		{
			Console.WriteLine("Hello from doPart()" + msg);
		}
		
	 	partial void doNothingPart(String[] args)
		;

		public partial class PartInner {
		}
		
#if MONO && (LINUX || INFILE)
		public String ToString() {
			return "PartialUser";
		}	
#endif	
	}
}

