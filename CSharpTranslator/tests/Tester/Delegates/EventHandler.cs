/*
   Copyright 2010-2013 Kevin Glynn (kevin.glynn@twigletsoftware.com)
   Copyright 2007-2013 Rustici Software, LLC

This program is free software: you can redistribute it and/or modify
it under the terms of the MIT/X Window System License

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You should have received a copy of the MIT/X Window System License
along with this program.  If not, see 

   <http://www.opensource.org/licenses/mit-license>
*/

// This example demonstrates the EventHandler<T> delegate.

using System;
using System.Collections.Generic;

namespace Tester.Delegates.EventHandler
{
//---------------------------------------------------------
	public class MyEventArgs : EventArgs
	{
		private string msg;

		public MyEventArgs (string messageData)
		{
			msg = messageData;
		}
		public string Message {
			get { return msg; }
			set { msg = value; }
		}
	}
//---------------------------------------------------------
	public class HasEvent
	{
// Declare an event of delegate type EventHandler of 
// MyEventArgs.

		public event EventHandler<MyEventArgs> SampleEvent;

		public void DemoEvent (string val)
		{
			// Copy to a temporary variable to be thread-safe.
			EventHandler<MyEventArgs> temp = SampleEvent;
			if (temp != null)
				temp (this, new MyEventArgs (val));
		}
	}
//---------------------------------------------------------
	public class Sample
	{
		public static void EHMain ()
		{
			HasEvent he = new HasEvent ();
			he.SampleEvent += new EventHandler<MyEventArgs> (SampleEventHandler);
			he.DemoEvent ("Hey there, Bruce!");
			he.DemoEvent ("How are you today?");
			he.DemoEvent ("I'm pretty good.");
			he.DemoEvent ("Thanks for asking!");
		}
		private static void SampleEventHandler (object src, MyEventArgs mea)
		{
			Console.WriteLine (mea.Message);
		}
	}
}
//---------------------------------------------------------
/*
This example produces the following results:

Hey there, Bruce!
How are you today?
I'm pretty good.
Thanks for asking!

*/

