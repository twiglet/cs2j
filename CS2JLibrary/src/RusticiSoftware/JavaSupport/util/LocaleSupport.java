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

package RusticiSoftware.JavaSupport.util;

import java.util.Locale;

public class LocaleSupport {

	// INVARIANT is the same as Locale.ROOT in Java 6.0.  If necessary we can alter it
	// here to have the desired features.
	public static final Locale INVARIANT = new Locale("","","");
	
	// singleton
	private LocaleSupport() {}
	
	private static ThreadLocal threadLocal = new InheritableThreadLocal();

	public static void setCurrentLocale(Locale locale) {
		threadLocal.set(locale);
	}

	public static Locale getCurrentLocale() {
		Locale locale = (Locale) threadLocal.get();
		
		if (locale == null) {
			return Locale.getDefault();
		} else {
			return locale;
		}
	}
	
}
