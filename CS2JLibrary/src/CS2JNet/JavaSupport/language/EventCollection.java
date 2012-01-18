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
package CS2JNet.JavaSupport.language;

import java.util.List;

import CS2JNet.JavaSupport.CS2JRunTimeException;

// TODO: T should implement a delegate type
public class EventCollection<T> implements IEventCollection<T> {
	
	List<T> listeners = null;
	
	/* (non-Javadoc)
	 * @see CS2JNet.JavaSupport.language.IEventCollection#Invoke(java.lang.Object, CS2JNet.JavaSupport.language.EventArgs)
	 */
	public void Invoke(Object cause, EventArgs e) throws CS2JRunTimeException {
	    if (listeners != null) {
	    	// do something here
	    	throw new CS2JRunTimeException("CS2J: Events are not yet implemented");
	    }
	}

}
