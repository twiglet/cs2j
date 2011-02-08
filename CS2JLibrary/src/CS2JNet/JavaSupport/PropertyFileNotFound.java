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

package CS2JNet.JavaSupport;

public class PropertyFileNotFound extends Exception {

	/**
	 * 
	 */
	private static final long serialVersionUID = 5628932360862279729L;

	/**
	 * 
	 */
	public PropertyFileNotFound() {
	}

	/**
	 * @param arg0
	 */
	public PropertyFileNotFound(String arg0) {
		super(arg0);
	}

	/**
	 * @param arg0
	 */
	public PropertyFileNotFound(Throwable arg0) {
		super(arg0);
	}

	/**
	 * @param arg0
	 * @param arg1
	 */
	public PropertyFileNotFound(String arg0, Throwable arg1) {
		super(arg0, arg1);
	}

}
