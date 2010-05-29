/*
[The "BSD licence"]
Copyright (c) 2002-2005 Kunle Odutola
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


namespace RusticiSoftware.Translator
{
	using System;
	using FileInfo					= System.IO.FileInfo;
	using IToken					= antlr.IToken;
	using TokenCreator				= antlr.TokenCreator;
	using CommonHiddenStreamToken	= antlr.CommonHiddenStreamToken;

	/// <summary>
	/// A sub-class of antlr.CommonHiddenStreamToken that can be used to track the
	/// file from which a token was created.
	///
	/// Has an ugly but convenient dependency on the CSharpParser class. See
	/// ToString() below.
	/// </summary>
	/// 
	public class CustomHiddenStreamToken : CommonHiddenStreamToken 
	{
		private string		filename_;
		private FileInfo	fileinfo_;

		protected CustomHiddenStreamToken() : base()
		{
		}
		
		public CustomHiddenStreamToken(int t, string txt) : base(t, txt)
		{
		}
		
		public CustomHiddenStreamToken(int t, string txt, FileInfo fileinfo) : base(t, txt)
		{
			fileinfo_ = fileinfo;
		}
		
		public CustomHiddenStreamToken(int t, string txt, FileInfo fileinfo, int line, int col) : base(t, txt)
		{
			this.fileinfo_	= fileinfo;
			this.line		= line;
			this.col		= col;
		}
		
		public override string getFilename()
		{
			if (fileinfo_ != null)
				return fileinfo_.FullName;
			else
				return null;
		}

		override public string ToString()
		{
			return "[\"" + getText() + "\",<" + CSharpParser.tokenNames_[type_] + ">,line=" + line + ",col=" + col + "]";
		}
		
		/// <summary>
		/// Sets the source file of the token
		/// </summary>
		///
		public FileInfo File
		{
			[System.Diagnostics.DebuggerStepThrough]
			get { return fileinfo_;  }
			[System.Diagnostics.DebuggerStepThrough]
			set { fileinfo_ = value; }
		}

		/// <summary>
		/// Gets or sets the contents of the hidden-before token stream.
		/// </summary>
		///
		public CustomHiddenStreamToken HiddenBefore
		{
			[System.Diagnostics.DebuggerStepThrough]
			get { return (CustomHiddenStreamToken) hiddenBefore;  }
			[System.Diagnostics.DebuggerStepThrough]
			set { hiddenBefore = (CommonHiddenStreamToken) value; }
		}

		/// <summary>
		/// Gets or sets the contents of the hidden-after token stream.
		/// </summary>
		///
		public CustomHiddenStreamToken HiddenAfter
		{
			[System.Diagnostics.DebuggerStepThrough]
			get { return (CustomHiddenStreamToken) hiddenAfter;  }
			[System.Diagnostics.DebuggerStepThrough]
			set { hiddenAfter = (CommonHiddenStreamToken) value; }
		}

		public class CustomHiddenStreamTokenCreator : TokenCreator
		{
			public CustomHiddenStreamTokenCreator() {}

			/// <summary>
			/// Returns the fully qualified name of the Token type that this
			/// class creates.
			/// </summary>
			public override string TokenTypeName
			{
				[System.Diagnostics.DebuggerStepThrough]
				get 
				{
					return typeof(CustomHiddenStreamToken).FullName;; 
				}
			}

			/// <summary>
			/// Constructs a <see cref="Token"/> instance.
			/// </summary>
			public override IToken Create()
			{
				return new CustomHiddenStreamToken();
			}
		}
	}
}