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

package CS2JNet.System.LCC;

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

import CS2JNet.JavaSupport.util.ListSupport;

/**
 * @author keving
 *
 */
public class __MultiPredicate<T> implements Predicate<T> {
 
	public boolean invoke(T obj) throws Exception {
        List<Predicate<T>> copy, members = this.getInvocationList();
        synchronized (members)
        {
            copy = new LinkedList<Predicate<T>>(members);
        }
        boolean ret = false;
        for (Predicate<T> d : copy)
        {
            ret = d.invoke(obj);
        }
        return ret;
    }

    private List<Predicate<T>> _invocationList = new ArrayList<Predicate<T>>();
    public static <T>Predicate<T> combine(Predicate<T> a, Predicate<T> b) throws Exception {
        if (a == null)
            return b;
         
        if (b == null)
            return a;
         
        __MultiPredicate<T> ret = new __MultiPredicate<T>();
        ret._invocationList = a.getInvocationList();
        ret._invocationList.addAll(b.getInvocationList());
        return ret;
    }

    public static <T>Predicate<T> remove(Predicate<T> a, Predicate<T> b) throws Exception {
        if (a == null || b == null)
            return a;
         
        List<Predicate<T>> aInvList = a.getInvocationList();
        List<Predicate<T>> newInvList = ListSupport.removeFinalStretch(aInvList, b.getInvocationList());
        if (aInvList == newInvList)
        {
            return a;
        }
        else
        {
            __MultiPredicate<T> ret = new __MultiPredicate<T>();
            ret._invocationList = newInvList;
            return ret;
        } 
    }

    public List<Predicate<T>> getInvocationList() throws Exception {
        return _invocationList;
    }
	

}
