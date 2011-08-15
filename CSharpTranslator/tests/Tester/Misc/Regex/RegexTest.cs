using System;
using System.Text.RegularExpressions;

namespace Tester.Misc
{
	public class RegexTest
	{
		public RegexTest ()
		{
		}
		
		public static void RegexMain() {
			
            Regex r = new Regex(@"(\d+)\s+(\d+)");
            Match m = r.Match("  001 002  003 004 ");
            while (m.Success)
            {
				Console.WriteLine("Match: '{0}'", m.Value);
				for (int i = 0; i < 3; i++) {
                	if (m.Groups[i] != null && m.Groups[i].Value.Length > 0)
                	{
                    	Console.WriteLine("Group {0}: '{1}'", i, m.Groups[i].Value);
					}
				}	
                
				m = m.NextMatch();
			}
            MatchCollection matches = r.Matches("  001 002  003 004 ");
            foreach (Match mi in matches)
            {
				Console.WriteLine("Match: '{0}'", mi.Value);
				for (int i = 0; i < 3; i++) {
                	if (mi.Groups[i] != null && mi.Groups[i].Value.Length > 0)
                	{
                    	Console.WriteLine("Group {0}: '{1}'", i, mi.Groups[i].Value);
					}
				}	
			}
		}
	}
}

