using System;
using System.Collections;

namespace CS2JTesterProject
{
	class MainClass
	{
		public static void Main (string[] args)
		{
			Console.WriteLine ("Hello World!");
			
			foreach(Char c in "Hello World") {
				Console.Write (c);
			}
		
			foreach(Char c in new ArrayList()) {
				Console.Write (c);
		
			}
		}
	}
}

