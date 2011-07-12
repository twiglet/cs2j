#define INFILE
	
using System;
namespace Tester
{
	public partial class PartialUser
	{
		
		string msg = "hello";
		
		public bool doIt(String[] args) {
			doNothingPart(args);
			doPart(args);
			return true;
		}

	 	partial void doPart(String[] args)
		;
		
		public static void PartialMain(String[] args) {
			PartialUser part = new PartialUser();
			part.doIt(args);
		}
	}
	

	

}

