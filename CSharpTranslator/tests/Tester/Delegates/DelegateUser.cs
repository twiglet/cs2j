using System;
using System.Collections.Generic;

namespace Tester.DelegateUser
{

	public delegate void CompleteCallback (String name, bool result);

	public delegate bool Predicate<T> (T value);

	public delegate void Del<T> (T value);

        [Serializable]
	public class DelegateTest<U>
	{

		public delegate void NodeSysLogHandler(string fname);
        public static event NodeSysLogHandler OnNodeSysLogHandler;                      // Event handler is fired on change event
	
		public void EventLogger() {
			       
			OnNodeSysLogHandler += fname => Console.WriteLine("Log:" + fname);



            if (OnNodeSysLogHandler != null)
            {
                 OnNodeSysLogHandler("log");
                 return;
            }
		}


		private Predicate<String> predDel = value => value == "Hello";
		//private event CompleteCallback cbackMember2 = null;
		private event CompleteCallback cbackMember = null;

		public CompleteCallback cbackProperty { get; set; }

		public Del<String> printProp { get; set; }

		delegate void TestDelegate (string s);
		delegate void TestRefDelegate (string s, ref int cumul);
		delegate void ProcessStringArray(string[] args);
		static void M (string s)
		{
			Console.WriteLine (s);
		}

		public void Notify (string i)
		{
			Console.Out.WriteLine ("Notify: {0}", i);
		}

		public void PrintMessages (string[] msgs)
		{
			foreach (string s in msgs) {
				Console.Out.WriteLine ("Message: {0}", s);
			}
		}

		public void UserResponse (String nameParam, bool resultParam)
		{
			Console.Out.WriteLine ("{0} was {1}", nameParam, resultParam);
		}

		public void Init (string[] args)
		{
			
			cbackMember = UserResponse;
			cbackProperty = new CompleteCallback (UserResponse);
		}

		public void ProcessArray ()
		{
			ProcessStringArray delg = PrintMessages;
			
			delg(new string[] {"Hello","Kevin"});
		}

		public void SwingIt ()
		{
			CompleteCallback cback = new CompleteCallback (UserResponse);
			CompleteCallback cback1 = null;
			cback1 = UserResponse;
			
			CompleteCallback cback2 = new CompleteCallback (this.cbackProperty);
			
			cback ("kevin", true);
			cback1 ("lizzie", true);
			cback2 ("jessie", false);
			
			Del<string> d1 = new Del<string> (Notify);
			
			d1 ("456");
			
			cbackMember ("fred", false);
			this.cbackProperty ("thomas", true);
			
			
			// Original delegate syntax required 
			// initialization with a named method.
			TestDelegate testDelA = new TestDelegate (M);
			
			// C# 2.0: A delegate can be initialized with
			// inline code, called an "anonymous method." This
			// method takes a string as an input parameter.
			TestDelegate testDelB = delegate(string s) { Console.WriteLine (s); };
			
			// C# 3.0. A delegate can be initialized with
			// a lambda expression. The lambda also takes a string
			// as an input parameter (x). 
			TestDelegate testDelC = (string x) => { Console.WriteLine (x); };
			
			// C# 3.0. A delegate can be initialized with
			// a lambda expression. The lambda also takes a string
			// as an input parameter (x). The type of x is inferred by the compiler.
			TestDelegate testDelD = x => { Console.WriteLine (x); };
			
			// Invoke the delegates.
			testDelA ("Hello. My name is M and I write lines.");
			testDelB ("That's nothing. I'm anonymous and ");
			testDelC ("I'm a famous author.");
			
			TestRefDelegate testDela = delegate (string x, ref int cumul) { cumul += 1; Console.WriteLine (x); Console.WriteLine ("cumul is {0}", cumul); };
			TestRefDelegate testDelb = (string x, ref int cumul) => { cumul += 3; Console.WriteLine (x); Console.WriteLine ("cumul is {0}", cumul); };
			TestRefDelegate testDelc = (string x, ref int cumul) => { cumul += 2; Console.WriteLine (x); Console.WriteLine ("cumul is {0}", cumul); };
                        TestRefDelegate testDeld = testDela + testDelb + testDelc;
                        int mycumulator = 0;
                        testDeld("RefAccumulator", ref mycumulator);
                        
		}

		delegate void DelC (string s);

		static void Hello (string s)
		{
			System.Console.WriteLine ("  Hello, {0}!", s);
		}

		static void Goodbye (string s)
		{
			System.Console.WriteLine ("  Goodbye, {0}!", s);
		}

		void HelloGoodbye ()
		{
			DelC a, b, c, d;
			
			// Create the delegate object a that references 
			// the method Hello:
			a = Hello;
			
			// Create the delegate object b that references 
			// the method Goodbye:
			b = Goodbye;
			
			// The two delegates, a and b, are composed to form c: 
			c = a + b;
			
			// Remove a from the composed delegate, leaving d, 
			// which calls only the method Goodbye:
			d = c - a;
			
			System.Console.WriteLine ("Invoking delegate a:");
			a ("A");
			System.Console.WriteLine ("Invoking delegate b:");
			b ("B");
			System.Console.WriteLine ("Invoking delegate c:");
			c ("C");
			System.Console.WriteLine ("Invoking delegate d:");
			d ("D");
			
			
			d += c;
			
			d += c;
			
			d -= c;

			System.Console.WriteLine ("Invoking composed delegate d:");
			d ("DA");

			Del<String> myt = x => Console.WriteLine("And so goodbye from " + x);
			this.printProp = x => Console.WriteLine("Hello from " + x);
			this.printProp += myt;
			printProp += x => Console.WriteLine("And goodbye from " + x);
			printProp("kevin");			
			this.printProp -= myt;
			
			printProp("des");			
		}


		public static void DelMain (string[] args)
		{
			DelegateTest<string> myDel = new DelegateTest<string> ();
			myDel.Init (args);
			myDel.SwingIt ();
			myDel.HelloGoodbye ();
			myDel.EventLogger();
			myDel.ProcessArray();
		}
	}
}
