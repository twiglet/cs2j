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

package CS2JNet.System.Collections.LCC;

import java.util.Collection;


/**
 * Mimics Net's IEnumerator interface
 * 
 * @author keving
 *
 * @param <T>
 */
public interface ICollection<T> extends IEnumerable<T>,Collection<T> {
	

    public   boolean Contains(T x) throws Exception;
    
    public   void Add(T x) throws Exception;
    
    public   boolean Remove(T x) throws Exception;

    public   void Clear() throws Exception;

    public   IEnumerator<T> getEnumerator() throws Exception;

    public   void copyTo(T[] arr,  int i) throws Exception;

}
