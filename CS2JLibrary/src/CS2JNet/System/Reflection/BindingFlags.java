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

package CS2JNet.System.Reflection;

public class BindingFlags {

	// It doesn't seem to be defined what is DEFAULT, and it also doesn't seem
	// to be defined what is getFields with no flags.
	// Here we assume no flags == DEFAULT, and we make up a likely DEFAULT
	public static int getDefault() {
		return getPublic() | getInstance();
	}

	public static int getIgnoreCase() {
		return 2;
	}

	public static int getDeclaredOnly() {
		return 4;
	}

	public static int getInstance() {
		return 8;
	}

	public static int getStatic() {
		return 0x10;
	}

	public static int getPublic() {
		return 0x20;
	}

	public static int getNonPublic() {
		return 0x40;
	}

	public static int getFlattenHierarchy() {
		return 0x80;
	}

}
