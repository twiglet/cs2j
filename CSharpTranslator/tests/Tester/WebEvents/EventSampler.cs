//   Copyright (c) 2011 Kevin Glynn (http://www.twigletsoftware.com)
//
// The MIT License (Expat)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
// and associated documentation files (the "Software"), to deal in the Software without restriction, 
// including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial 
// portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
// LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

using System;
using System.Collections.Generic;

namespace Twiglet.Sample.Event
{

    /// <summary>
    /// Sample class to show off CS2J's translations for events.
	/// 
	/// A StorePublisher object stores a list of thingummys.  Thingummys
	/// can be added to the store and the store can be cleared. (For brevity
	/// we omit methods to retrieve thingummys from the store!).
	/// 
	/// The StorePublisher has two events, one fires when items are added, the
	/// other fires when the store is cleared. Callers to Add and Clear pass
	/// a name, and this name is sent to the event subscribers.
	/// 
    /// </summary>
	public class StorePublisher<T>
	{
        private List<T> store = null;

        // The events raised by this Store Publisher
        public event EventHandler<ClearEventArgs> RaiseClearedEvent;
        public event EventHandler<StoreEventArgs<T>> RaiseStoredEvent;

        // raise the Clear event
        protected virtual void OnRaiseClearedEvent(ClearEventArgs e)
        {
            if (RaiseClearedEvent != null)
             {
                // invoke the waiting subscribers.
                 RaiseClearedEvent(this, e);
            }
        }

        // raise the Store event
        protected virtual void OnRaiseStoredEvent(StoreEventArgs<T> e)
        {
            if (RaiseStoredEvent != null)
            {
                // invoke the waiting subscribers.
                RaiseStoredEvent(this, e);
            }
        }

        public void Clear(string requestor)
        {
            store = new List<T>();
            OnRaiseClearedEvent(new ClearEventArgs(requestor));
        }

        public void Add(string requestor, T data)
        {
            if (store == null)
            {
                Clear("Add");
            }
            store.Add(data);
            OnRaiseStoredEvent(new StoreEventArgs<T>(requestor, data));
        }
	}

 
    /// <summary>
    /// EventArgs derived class to pass info about a request to clear store
    /// </summary>
    public class ClearEventArgs : EventArgs
    {
        public ClearEventArgs(string req) { this.Requestor = req; }
        public string Requestor { get; set; }
    }

    /// <summary>
    /// EventArgs derived class to pass info about a request to add data to store
    /// </summary>
    public class StoreEventArgs<T> : EventArgs
    {
        public StoreEventArgs(string req, T data) { this.Requestor = req; this.Data = data; }
        public string Requestor { get; set; }
        public T Data { get; set; }
    }

    /// <summary>
    /// Info about the type of subscription a subscriber requested
    /// </summary>
    public enum SubscriptionType { NewSubscriber, ClearRequest, StoreData }

    /// <summary>
    /// EventArgs derived class to pass info about a new subscriber
    /// </summary>
    public class SubscribeEventArgs : EventArgs
    {
        public SubscribeEventArgs(string sub, SubscriptionType ty) { this.Subscriber = sub; this.SubnType = ty; }
        public string Subscriber { get; set; }
        public SubscriptionType SubnType { get; set; } 
    }

    public class StoreSubscriber<T>
    {
		/// <summary>
		/// Name identifies this subscriber in the trace.
		/// </summary>
		/// <value>
		/// The name.
		/// </value>
        public string Name { get; set; }
		
        public StoreSubscriber(string n)
        {
            Name = n;
        }
		
		/// <summary>
		/// We subscribe to both StorePublisher events.
		/// </summary>
		/// <param name='store'>
		/// Store.
		/// </param>
        public void SubscribeToStore(StorePublisher<T> store) {
            store.RaiseClearedEvent += new EventHandler<ClearEventArgs>(OnClearEvent);
            store.RaiseStoredEvent += new EventHandler<StoreEventArgs<T>>(OnStoreEvent);
        }

        private void OnClearEvent(object sender, ClearEventArgs e)
        {
            Console.WriteLine(Name + ": " + e.Requestor + " cleared the Store");
        }
        private void OnStoreEvent(object sender, StoreEventArgs<T> e)
        {
            Console.WriteLine(Name + ": " + e.Requestor + " added " + e.Data.ToString() + " to the Store");
        }
    }

    public static class EventSampler
    {
        public static string MYID = "StoreUser";

        public static void EventSamplerMain(string[] args)
        {
			
			// Create StorePublisher instance
            StorePublisher<string> s = new StorePublisher<string>();

			// Add first subscriber
            new StoreSubscriber<string>("Subscriber A").SubscribeToStore(s);
			
			// Generates events for initial clear and the add
			s.Add(MYID, "Store Ham");
			
			// Generates an add event
            s.Add(MYID, "Store Eggs");
			
			// Add second subscriber
            new StoreSubscriber<string>("Subscriber B").SubscribeToStore(s);
			
			// Both subscribers are notified of add
            s.Add(MYID, "Store Milk");
			
			// Both subscribers are notified of clear
            s.Clear(MYID);
        }

    }

}
