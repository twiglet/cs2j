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

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

import CS2JNet.JavaSupport.util.ListSupport;

/**
 * @author keving
 *
 */
public class __MultiAction<T> implements Action<T> {
 
	public void Invoke(T obj) throws Exception {
        List<Action<T>> copy, members = this.GetInvocationList();
        synchronized (members)
        {
            copy = new LinkedList<Action<T>>(members);
        }
        for (Action<T> d : copy)
        {
            d.Invoke(obj);
        }
    }

    private List<Action<T>> _invocationList = new ArrayList<Action<T>>();
    public static <T>Action<T> Combine(Action<T> a, Action<T> b) throws Exception {
        if (a == null)
            return b;
         
        if (b == null)
            return a;
         
        __MultiAction<T> ret = new __MultiAction<T>();
        ret._invocationList = a.GetInvocationList();
        ret._invocationList.addAll(b.GetInvocationList());
        return ret;
    }

    public static <T>Action<T> Remove(Action<T> a, Action<T> b) throws Exception {
        if (a == null || b == null)
            return a;
         
        List<Action<T>> aInvList = a.GetInvocationList();
        List<Action<T>> newInvList = ListSupport.removeFinalStretch(aInvList, b.GetInvocationList());
        if (aInvList == newInvList)
        {
            return a;
        }
        else
        {
            __MultiAction<T> ret = new __MultiAction<T>();
            ret._invocationList = newInvList;
            return ret;
        } 
    }

    public List<Action<T>> GetInvocationList() throws Exception {
        return _invocationList;
    }
	

}
