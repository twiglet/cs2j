/*
   Copyright 2007-2010 Rustici Software, LLC

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   Author(s):

   Kevin Glynn (kevin.glynn@scorm.com)
*/

package CS2JNet.System;

public class ConsoleSupport {

	// Takes a C# format string and vonverts it to a Java format string
	public static String CSFmtStrToJFmtStr(String fmt)
	{
		return fmt.replaceAll("\\{(\\d)+\\}", "%$1\\$s");		
	}
	
	public static void testMain(String[] args)
	{
		System.out.printf(CSFmtStrToJFmtStr("DECLARATION: {0}={1}") + "\n", "Kevin", "Great");
		System.out.printf(CSFmtStrToJFmtStr("DECLARATION: {0}={1}"), "Kevin", "Great");
	}
}
