/*
   Copyright 2009-2012 Andrew Bradnan (http://antlrcsharp.codeplex.com/)

This program is free software: you can redistribute it and/or modify
it under the terms of the MIT/X Window System License

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You should have received a copy of the MIT/X Window System License
along with this program.  If not, see 

   <http://www.opensource.org/licenses/mit-license>
*/

// PreProcessor.cs
//

using System;
using System.Collections.Generic;
using System.Text;
using Antlr.Runtime;
using System.Diagnostics;

namespace AntlrCSharp
{
    /// <summary> PreProcessor
    ///   The lexer preprocesses the CSharp code.
    /// </summary>
    public class PreProcessor : csLexer
	{
        // if there's an #if / #else mismatch, don't complain every token :)
		bool Warn = true;
        private bool _foundMeat = false;
        public bool FoundMeat
        {
            get { return _foundMeat; }
            set { _foundMeat = value; }
        }


		public PreProcessor()
		{
			// By default we are preprocessing input
			Processing.Push(true);


		}
        public void AddDefine(string def)
        {
            MacroDefines.Add(def, string.Empty);
        }

        public void AddDefine(ICollection<string> defs)
        {
            foreach (string def in defs) {
                MacroDefines.Add(def, string.Empty);
            }
        }

        public override void mTokens()
		{
			base.mTokens();
			// if we aren't processing, skip this token
			// if the Count is 0, we are in a bad state.
			if (Processing.Count > 0)
			{
				if (Processing.Peek() == false)
                    state.token = Antlr.Runtime.Tokens.Skip;
            }
			else if (Warn)
			{
				// Don't warn every token
				Warn = false;
				Debug.Assert(Processing.Count > 0, "Stack underflow preprocessing.  mTokens");
				Console.WriteLine("Found unexpected else.");
			}
		}
		
        // Code for Emiting new tokens
        // I Emit() multiple tokens in the case of 0123.ToString()
        // TODO:  There's a better way to do this just in the grammar (who knew)!  This works fine at the moment.
		Queue<IToken> Tokens = new Queue<IToken>();
		public override void Emit(IToken token)
		{
			state.token = token;
			Tokens.Enqueue(token);
            if (token.Channel == TokenChannels.Default)
            {
                FoundMeat = true;
            }
		}
		public override IToken NextToken()
		{
			base.NextToken();
			if (Tokens.Count == 0)
			{
				return Antlr.Runtime.Tokens.EndOfFile;
			}
			return Tokens.Dequeue();
		}

 /*
        /// <summary>
        /// These two functions prints a stack of rules for a failure.  It sounds really useful but it's mostly noise and didn't
        /// help me locate errors any quicker (mostly slower).  Feel free to comment out.
        /// From "The ANTLR Reference" pg. 247 (translated to C#)
        /// </summary>
		public override String GetErrorMessage(RecognitionException e, String[] tokenNames)
		{
			IList<string> stack = GetRuleInvocationStack(e, this.GetType().Name);
			StringBuilder sb = new StringBuilder();
			sb.Append("\r\n");
			foreach (object o in stack)
				sb.AppendFormat("{0}\r\n", o);

			if (e is NoViableAltException)
			{
				NoViableAltException nvae = (NoViableAltException)e;
				sb.AppendFormat(" no viable alt; token = {0} (decision = {1} state {2}) decision=<<{3}>>\r\n",
					e.Token.Text,
					nvae.decisionNumber,
					nvae.stateNumber,
					nvae.grammarDecisionDescription);
			}
			else
				sb.Append(base.GetErrorMessage(e, tokenNames));

			return sb.ToString();
		}
  */
		public override String GetTokenErrorDisplay(IToken t)
		{
			return t.ToString();
		}
		public override void ReportError(RecognitionException e)
		{
			// Ignore lexer errors in parts of the file that the preprocessor is ignoring.
			// So, only report error if we are processing at the moment. 
			if (Processing.Peek())
				base.ReportError(e);
		}
	}
}
