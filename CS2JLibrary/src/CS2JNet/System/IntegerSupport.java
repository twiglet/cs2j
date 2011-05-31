/*
   Copyright 2007,2008,2009,2010 Rustici Software, LLC
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)

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

   Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

package CS2JNet.System;

import java.text.NumberFormat;
import java.text.ParseException;

import CS2JNet.JavaSupport.util.LocaleSupport;
import CS2JNet.System.Globalization.*;

public class IntegerSupport {
	
	public static int parse(String s, int style) throws ParseException
	{
		String toParse = s;
		
		if ((style & NumberStyles.getAllowLeadingWhite()) > 0)
			   toParse = StringSupport.TrimStart(toParse, null);

		if ((style & NumberStyles.getAllowTrailingWhite()) > 0)
			   toParse = StringSupport.TrimEnd(toParse, null);

		if ((style & NumberStyles.getAllowLeadingSign()) == 0)
			   if (toParse.charAt(0) == '+' || toParse.charAt(0) == '-')
				   throw new ParseException("Signs not allowed: " + s, 0);

		if ((style & NumberStyles.getAllowHexSpecifier()) > 0)
			return Integer.parseInt(toParse, 16);
		
		return NumberFormat.getInstance(LocaleSupport.INVARIANT).parse(toParse).byteValue();
		
	}

	public static String mkString(int i, String style) throws NotImplementedException
	{
		if (style.toLowerCase().equals("x")) {
			String retStr = Integer.toHexString(i);
			if (style.equals("X")) {
				return retStr.toUpperCase();
			}
			return retStr;
		}
		
		if (style.toLowerCase().startsWith("d")) {
			String width = "";
			if (style.length() > 1)
				width = "0" + String.valueOf(Integer.valueOf(style.substring(1)) + (i < 0 ? 1 : 0));
			String fmt = "%0$"+width+"d";
			String retStr = String.format(fmt, i);
			return retStr;
		}
		
		throw new NotImplementedException("IntegerSupport.mkString does not support format string  '" + style + "'");
	}
	
	public static void main(String[] args) throws NotImplementedException {
		int integral = 8395;
	    System.out.printf("D: %0$s\n", mkString(integral, "D"));
	    System.out.printf("D: %0$s\n", mkString(integral, "D6"));
	    System.out.printf("D: %0$s\n", mkString(-integral, "D6"));
	
	}

}
