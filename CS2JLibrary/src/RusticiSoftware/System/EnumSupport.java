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

public class EnumSupport {

	// returns true iff v is a valid ordinal position of a enum in e
	public static boolean isDefined(Class e, int v)
	{
		return (v >= 0 && v < e.getEnumConstants().length);
	}
	
	public static String toString(Enum e, String m)
	{
		if ("D".equals(m))
		{
			return String.valueOf(e.ordinal());
		}
		else
		{
			return e.name();
		}
		
	}
}
