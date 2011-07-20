using System;
using System.Collections.Generic;

namespace Tester.Misc.Sorter
{
	public class Example : IComparer<string>
	{
		private static int CompareDinosByLength (string x, string y)
		{
			if (x == null) {
				if (y == null) {
					// If x is null and y is null, they're
					// equal. 
					return 0;
				} else {
					// If x is null and y is not null, y
					// is greater. 
					return -1;
				}
			} else {
				// If x is not null...
				//
				// ...and y is null, x is greater.
				if (y == null) {
					return 1;
				} else {
					// ...and y is not null, compare the 
					// lengths of the two strings.
					//
					int retval = x.Length.CompareTo (y.Length);
					
					if (retval != 0) {
						// If the strings are not of equal length,
						// the longer string is greater.
						//
						return retval;
					} else {
						// If the strings are of equal length,
						// sort them with ordinary string comparison.
						//
						return x.CompareTo (y);
					}
				}
			}
		}
		
		public int Compare(String x, String y) {
			return CompareDinosByLength(x,y);
		}

		public static void SorterMain ()
		{
			List<string> dinosaurs = new List<string> ();
			dinosaurs.Add ("Pachycephalosaurus");
			dinosaurs.Add ("Amargasaurus");
			dinosaurs.Add ("");
			dinosaurs.Add (null);
			dinosaurs.Add ("Mamenchisaurus");
			dinosaurs.Add ("Deinonychus");
			Display (dinosaurs);
			
			Console.WriteLine ("\nSort with generic Comparison<string> delegate:");
			dinosaurs.Sort (new Example());
			Display (dinosaurs);
			
		}

		private static void Display (List<string> list)
		{
			Console.WriteLine ();
			foreach (string s in list) {
				if (s == null)
					Console.WriteLine ("(null)");
				else
					Console.WriteLine ("\"{0}\"", s);
			}
		}
	}
	
}
/* This code example produces the following output:

"Pachycephalosaurus"
"Amargasaurus"
""
(null)
"Mamenchisaurus"
"Deinonychus"

Sort with generic Comparison<string> delegate:

(null)
""
"Deinonychus"
"Amargasaurus"
"Mamenchisaurus"
"Pachycephalosaurus"
 */
