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

namespace Twiglet.Sample.Delegate
{

    /// <summary>
    /// Sample class to show off CS2J's translations for delegates and events 
    /// </summary>
	public class DelegateSampler
	{
        //
        /// <summary>
        /// LogWriters take a string and record it.
        /// </summary>
        /// <param name="logMessage">the message to be recorded</param>
		public delegate void LogWriter(string logMessage);

        /// <summary>
        /// A chain of delegates can't pass values to each other, (only the value
        /// returned from the final delegate is returned to the caller, the
        /// return values from intermediate delegates are just dropped on the floor).
        /// However the delegates can communicate if we use ref parameters.
        /// </summary>
        /// <param name="value">the variable that we are processing</param>
        public delegate void Processor<T>(ref T value);

        // This variable is captured by the delegates,  if we change this variable
        // then it changes what they print.
        private string _captured_string = "none";

        private void MethodDelegate(string s)
        {
            Console.WriteLine("MethodDelegate[" + _captured_string + "]:\t\t\t" + s);
        }

        private void MethodDelegateTwo(string s)
        {
            Console.WriteLine("MethodDelegateTwo[" + _captured_string + "]:\t\t" + s);
        }

        public void RunIt() {
			
            // First we create some delegates using the many syntaxes supported by C# 

			// Old fashioned delegate creation
			// initialize delegate with a named method.
            LogWriter delA = new LogWriter(MethodDelegate);

            // We can just also just assign a method group to a delegate variable
            LogWriter delB = MethodDelegateTwo;
			
			// Since C# 2.0 a delegate can be initialized with
			// an "anonymous method." 
            LogWriter delC = delegate(string s) { Console.WriteLine("AnonymousMethodDelegate[" + _captured_string + "]:\t\t" + s); };
			
			// Since C# 3.0 a delegate can be initialized with
			// a lambda expression. 
            LogWriter delD = (string s) => { Console.WriteLine("LambdaExpressionDelegate[" + _captured_string + "]:\t\t" + s); };
			
			// Since C# 3.0 a delegate can be initialized with
			// a lambda expression, the type of the argument is inferred by the compiler.
            LogWriter delE = s => { Console.WriteLine("InferredLambdaExpressionDelegate[" + _captured_string + "]:\t" + s); };
			
			// Invoke the delegates.
			delA("Peter Piper");
			delB("picked a peck");
            delC("of pickled peppers.");
            delD("A peck of pickled peppers");
            delE("Peter Piper picked.");

            // Change the captured parameter and run them again 
            this._captured_string = "aaaa";

            delA("Peter Piper");
            delB("picked a peck");
            delC("of pickled peppers.");
            delD("A peck of pickled peppers");
            delE("Peter Piper picked.");

            // Now Combine the delegates
            var chainDelegates = delA + delB + delC + delD + delE;

            // and invoke it
            chainDelegates("Chained Delegates");

            // remove delB and rerun
            chainDelegates -= delB;

            chainDelegates("Chained without MethodDelegateTwo");
            
            // Calculate (4 * (x^x)) + 1
            Processor<int> calcIt = (ref int x) => { x = x*x; };
            calcIt += (ref int x) => { x = 4 * x; };
            calcIt += (ref int x) => { x += 1; };
            int val = 5;
            calcIt(ref val);
            Console.WriteLine("(4 * (5^5)) + 1 = " + val);
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

		}


		public static void DelegateSamplerMain()
		{
			DelegateSampler sampler = new DelegateSampler ();
            sampler.RunIt();
		}
	}
}
