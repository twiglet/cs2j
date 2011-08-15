/*
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

/**
 * @author keving
 *
 */
public class SystemException extends Exception {
	
	public SystemException() {
		
	}
	
	public SystemException(String msg) {
		super(msg);
	}
	
	public SystemException(Throwable inner) {
		super(inner);
	}
	
	public SystemException(String msg, Throwable inner) {
		super(msg, inner);
	}
	

}
