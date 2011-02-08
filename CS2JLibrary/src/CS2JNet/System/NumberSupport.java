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

public class NumberSupport {

	
//	public static float round(float num, int places) {
//		long factor = (long)Math.pow(10,places);
//		return Math.round(num * factor) / factor;
//	}
	
	   /**
     * Round a double value to a specified number of decimal 
     * places.
     *
     * @param val the value to be rounded.
     * @param places the number of decimal places to round to.
     * @return val rounded to places decimal places.
     */
    public static double round(double val, int places) {
	long factor = (long)Math.pow(10,places);

	// Shift the decimal the correct number of places
	// to the right.
	val = val * factor;

	// Round to the nearest integer.
	long tmp = Math.round(val);

	// Shift the decimal the correct number of places
	// back to the left.
	return (double)tmp / factor;
    }

    /**
     * Format a number
     *
     * @param n the value to be formatted.
     * @param format a C# standard numeric format string.
     * @return n formatted according to C# format string.
     * @throws NotImplementedException 
     */
    public static String format(Number n, String format) throws NotImplementedException {
    	String fStr = null;
    	switch (format.charAt(0)){
		case 'X':
		case 'x':
    			fStr = String.format("%1$0" + format.substring(1) + format.charAt(0), n);
    			break;
    		default:
    			throw new NotImplementedException("No implementation for " + format + " format string");
    	}
		return fStr;
    }

	
	public static void main(String args[]) throws NotImplementedException {
		double f = 10.123456789d;
		System.out.println(f + " turns into " + round(f,3));
		for (int i = 0; i <= 255; i++) {
			byte b = (byte)i;
			System.out.println(b + " turns into " + format(b,"X2"));
		}
	}

}
