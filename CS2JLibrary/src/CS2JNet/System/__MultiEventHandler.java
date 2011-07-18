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
public class __MultiEventHandler<TEventArgs> implements EventHandler<TEventArgs> {
 
	public void Invoke(Object other, TEventArgs e) throws Exception {
        List<EventHandler<TEventArgs>> copy, members = this.GetInvocationList();
        synchronized (members)
        {
            copy = new LinkedList<EventHandler<TEventArgs>>(members);
        }
        for (EventHandler<TEventArgs> d : copy)
        {
            d.Invoke(other, e);
        }
    }

    private List<EventHandler<TEventArgs>> _invocationList = new ArrayList<EventHandler<TEventArgs>>();
    public static <TEventArgs>EventHandler<TEventArgs> Combine(EventHandler<TEventArgs> a, EventHandler<TEventArgs> b) throws Exception {
        if (a == null)
            return b;
         
        if (b == null)
            return a;
         
        __MultiEventHandler<TEventArgs> ret = new __MultiEventHandler<TEventArgs>();
        ret._invocationList = a.GetInvocationList();
        ret._invocationList.addAll(b.GetInvocationList());
        return ret;
    }

    public static <TEventArgs>EventHandler<TEventArgs> Remove(EventHandler<TEventArgs> a, EventHandler<TEventArgs> b) throws Exception {
        if (a == null || b == null)
            return a;
         
        List<EventHandler<TEventArgs>> aInvList = a.GetInvocationList();
        List<EventHandler<TEventArgs>> newInvList = ListSupport.removeFinalStretch(aInvList, b.GetInvocationList());
        if (aInvList == newInvList)
        {
            return a;
        }
        else
        {
            __MultiEventHandler<TEventArgs> ret = new __MultiEventHandler<TEventArgs>();
            ret._invocationList = newInvList;
            return ret;
        } 
    }

    public List<EventHandler<TEventArgs>> GetInvocationList() throws Exception {
        return _invocationList;
    }
	

}
