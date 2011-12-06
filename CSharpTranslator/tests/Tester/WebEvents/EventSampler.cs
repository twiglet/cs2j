//   Copyright 2011 Kevin Glynn (http://www.twigletsoftware.com)
//
// The MIT License (MIT)
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
    /// Sample class to show off CS2J's translations for events 
    /// </summary>
	public class StorePublisher
	{
        private List<string> store = null;

        // The events raised by this Store Publisher
        public event EventHandler<ClearEventArgs> RaiseClearedEvent;
        public event EventHandler<StoreEventArgs> RaiseStoredEvent;

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
        protected virtual void OnRaiseStoredEvent(StoreEventArgs e)
        {
            if (RaiseStoredEvent != null)
            {
                // invoke the waiting subscribers.
                RaiseStoredEvent(this, e);
            }
        }

        public void Clear(string requestor)
        {
            store = new List<string>();
            OnRaiseClearedEvent(new ClearEventArgs(requestor));
        }

        public void Add(string requestor, string data)
        {
            if (store == null)
            {
                Clear("Add, needed to service " + requestor);
            }
            store.Add(data);
            OnRaiseStoredEvent(new StoreEventArgs(requestor, data));
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
    public class StoreEventArgs : EventArgs
    {
        public StoreEventArgs(string req, string data) { this.Requestor = req; this.Data = data; }
        public string Requestor { get; set; }
        public string Data { get; set; }
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

    public class StoreSubscriber
    {
        public string Name { get; set; }

        public StoreSubscriber(string n)
        {
            Name = n;
        }

        public void SubscribeToStore(StorePublisher store) {
            store.RaiseClearedEvent += new EventHandler<ClearEventArgs>(OnClearEvent);
            store.RaiseStoredEvent += new EventHandler<StoreEventArgs>(OnStoreEvent);
        }

        private void OnClearEvent(object sender, ClearEventArgs e)
        {
            Console.WriteLine(Name + ": " + e.Requestor + " cleared the Store");
        }
        private void OnStoreEvent(object sender, StoreEventArgs e)
        {
            Console.WriteLine(Name + ": " + e.Requestor + " added " + e.Data + " to the Store");
        }
    }

    public static class EventSampler
    {
        public static string MYID = "MAIN";

        public static void EventSamplerMain(string[] args)
        {

            StorePublisher s = new StorePublisher();
            s.Add(MYID, "Store Ham");

            // Add two subscribers
            StoreSubscriber sub1 = new StoreSubscriber("Subscriber A");
            sub1.SubscribeToStore(s);

            s.Add(MYID, "Store Eggs");

            StoreSubscriber sub2 = new StoreSubscriber("Subscriber B");
            sub2.SubscribeToStore(s);
            s.Add(MYID, "Store Milk");

            s.Add("Main", "Hello World");
        }

    }

}
