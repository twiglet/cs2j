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

package CS2JNet.System.Collections.Generic;

import java.util.Set;


/**
 * @author kevin.glynn@twigletsoftware.com
 *
 */
public class KeyCollectionSupport {
	

    public static <T> void CopyTo(Set<T> keys, T[] array, int index) {
    	if (keys == null)
			throw new NullPointerException("keys");
    	if (array == null)
			throw new NullPointerException("array");
    	
    	if (index < 0 || index + keys.size() > array.length)
    		throw new IllegalArgumentException("index");
    	
    	int i = 0;
    	for (T k : keys) {
    		array[index + i] = k;
    		i++;
    	}
    	if (index + i < array.length) {
    		array[index+i] = null;
    	}
    	
    }

}
