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
	using FileInfo							= System.IO.FileInfo;
	using StringBuilder						= System.Text.StringBuilder;
	using AST								= antlr.collections.AST;
	using BaseAST							= antlr.BaseAST;
	using ASTFactory						= antlr.ASTFactory;
	using IToken							= antlr.IToken;
	using CommonASTWithHiddenTokens			= antlr.CommonASTWithHiddenTokens;
	using CommonHiddenStreamToken			= antlr.CommonHiddenStreamToken;


	/// <summary>
	/// Summary description for ASTNode.
	/// </summary>
	/// 
	[Serializable()]
	public class ASTNode : CommonASTWithHiddenTokens
	{
		new public static readonly ASTNode.ASTNodeCreator Creator = new ASTNodeCreator();

		//---------------------------------------------------------------------
		// CONSTRUCTORS
		//---------------------------------------------------------------------

		public ASTNode() : base()
		{
			//
			// TODO: Add constructor logic here
			//
		}
		public ASTNode(IToken tok) : base(tok)
		{
		}

		//---------------------------------------------------------------------
		// PUBLIC METHODS
		//---------------------------------------------------------------------

		override public void initialize(antlr.collections.AST t)
		{
			base.initialize(t);
			ASTNode node = t as ASTNode;
			if (null != node)
			{
				Column		= node._column;
				Line		= node._line;
                DotNetType  = node._dotNetType;
				_fileinfo   = node._fileinfo;
				_previousSibling	= node._previousSibling;
				_parentNode			= node._parentNode;
			}
		}		
		override public void initialize(IToken tok)
		{
			base.initialize(tok);
			Column = tok.getColumn();
			Line   = tok.getLine();

			CustomHiddenStreamToken ctok = tok as CustomHiddenStreamToken;
			if (null != ctok)
			{
				File   = ctok.File;
			}
		}

		public virtual ASTNode GetFirstChildOfType(int type)
		{
			ASTNode result = null;
			
			AST sibling = getFirstChild();
			while (sibling != null)
			{
				if (sibling.Type == type)
				{
					result = (ASTNode) sibling;
					break;
				}
				sibling = sibling.getNextSibling();
			}
			
			return result;
		}

		public void CopyPositionFrom(ASTNode other)
		{
			Line   = other.Line;
			Column = other.Column;
		}
		
		//---------------------------------------------------------------------
		// ACCESSORS & MUTATORS
		//---------------------------------------------------------------------

		/// <summary>
		/// Gets or sets the contents of the hidden-before token stream.
		/// </summary>
		///
		public CustomHiddenStreamToken HiddenBefore
		{
			get { return (CustomHiddenStreamToken) hiddenBefore;  }
			set { hiddenBefore = (CommonHiddenStreamToken) value; }
		}

		/// <summary>
		/// Gets or sets the contents of the hidden-after token stream.
		/// </summary>
		///
		public CustomHiddenStreamToken HiddenAfter
		{
			get { return (CustomHiddenStreamToken) hiddenAfter;  }
			set { hiddenAfter = (CommonHiddenStreamToken) value; }
		}

		/// <summary>
		/// Gets or Sets the source file line position for this Node
		/// </summary>
		///
		public int Line
		{
			get { return _line; }
			set {_line = value; }
		}
		/// <summary>
		/// Gets or Sets the source file column position for this Node
		/// </summary>
		///
		public int Column
		{
			get { return _column; }
			set {_column = value; }
		}
		/// <summary>
		/// Gets or Sets the source file for this Node
		/// </summary>
		///
		public FileInfo File
		{
			get { return _fileinfo;  }
			set { _fileinfo = value; }
		}

        public TypeRep DotNetType
        {
            get { return _dotNetType; }
            set { _dotNetType = value; }
        }

        public ASTNode getParent() 
		{
			return _parentNode;
		}

		public ASTNode getPreviousSibling() 
		{
			return _previousSibling;
		}

		public void setParent(ASTNode parent) 
		{
			this._parentNode = parent;
		}

		public void setPreviousSibling(ASTNode previousSibling) 
		{
			this._previousSibling = previousSibling;
		}

		public virtual void  addChildEx(ASTNode node)
		{
			if (node == null)
				return ;
			ASTNode t = (ASTNode) this.down;
			if (t != null)
			{
				while (t.right != null)
				{
					t = (ASTNode) t.right;
				}
				t.right = (BaseAST) node;
				node._previousSibling = t;
				node._parentNode = this;
			}
			else
			{
				this.down = (BaseAST) node;
				node._parentNode		= this;
				node._previousSibling	= null;
			}
		}
		
		//---------------------------------------------------------------------
		// PRIVATE DATA MEMBERS
		//---------------------------------------------------------------------
		private int					_column				= -1;
		private int					_line				= -1;
		private FileInfo			_fileinfo;
		private ASTNode				_parentNode;
		private ASTNode				_previousSibling;
        private TypeRep             _dotNetType = null;

	

		public class ASTNodeCreator : antlr.ASTNodeCreator
		{
			public ASTNodeCreator() {}

			/// <summary>
			/// Returns the fully qualified name of the AST type that this
			/// class creates.
			/// </summary>
			public override string ASTNodeTypeName
			{
				get 
				{ 
					return typeof(ASTNode).FullName;; 
				}
			}

			/// <summary>
			/// Constructs a <see cref="AST"/> instance.
			/// </summary>
			public override AST Create()
			{
				return new ASTNode();
			}
		}
	}
}
