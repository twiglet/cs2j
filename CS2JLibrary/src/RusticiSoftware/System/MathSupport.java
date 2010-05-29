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

package RusticiSoftware.System;

public class MathSupport {

	
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
     * Round a float value to a specified number of decimal 
     * places.
     *
     * @param val the value to be rounded.
     * @param places the number of decimal places to round to.
     * @return val rounded to places decimal places.
     */
    public static float round(float val, int places) {
	return (float)round((double)val, places);
    }

	
	public static void main(String args[]) {
		double f = 10.123456789d;
		System.out.println(f + "turns into" + round(f,3));
	}

}
