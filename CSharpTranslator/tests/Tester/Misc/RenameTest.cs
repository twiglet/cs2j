using System;
namespace Tester.Misc
{
	public class RenameTest
	{
		public RenameTest ()
		{
		}
		
		public string AMethod(object x) {
			return "AMethod has arg " + x.ToString();
		}

		public string aMethod(string s) {
			return "aMethod has string arg \"" + s + "\"";
		}

		public static void RNMain(string arg) {
			RenameTest rnObj = new RenameTest();
			Console.Out.WriteLine(rnObj.AMethod(arg));
		}	
	}
	
}

