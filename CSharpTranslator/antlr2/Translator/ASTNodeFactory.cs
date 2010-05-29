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
	using FileInfo			= System.IO.FileInfo;
	using AST				= antlr.collections.AST;
	using ASTPair			= antlr.ASTPair;
	using ASTFactory		= antlr.ASTFactory;
	
	public class ASTNodeFactory : ASTFactory
	{
		//---------------------------------------------------------------------
		// CONSTRUCTORS
		//---------------------------------------------------------------------

		/// <summary>
		/// Constructs an <c>ASTNodeFactory</c> with the default AST node type.
		/// </summary>
		public ASTNodeFactory() :
			base(typeof(ASTNode).FullName)
		{
			setASTNodeCreator(new ASTNode.ASTNodeCreator());
		}

		/// <summary>
		/// Constructs an <c>ASTNodeFactory</c> with the specified AST node type
		/// as the default.
		/// </summary>
		/// <param name="nodeTypeName">Default AST node type name.</param>
		public ASTNodeFactory(string nodeTypeName) :
			base(typeof(ASTNode).FullName)
		{
			setASTNodeCreator(new ASTNode.ASTNodeCreator());
		}
		
		//---------------------------------------------------------------------
		// DATA MEMBERS
		//---------------------------------------------------------------------
		private FileInfo filefinfo_;


		//---------------------------------------------------------------------
		// FUNCTION MEMBERS
		//---------------------------------------------------------------------

		public FileInfo FileInfo
		{
			get { return filefinfo_;  }
			set { filefinfo_ = value; }
		}

		/// <summary>
		/// Add a child to the current AST
		/// </summary>
		/// <param name="currentAST">The AST to add a child to</param>
		/// <param name="child">The child AST to be added</param>
		public override void  addASTChild(ref ASTPair currentAST, AST child)
		{
			if (child != null)
			{
				if (currentAST.root == null)
				{
					// Make new child the current root
					currentAST.root = child;
					((ASTNode) child).setParent(null);
				}
				else
				{
					((ASTNode) child).setParent((ASTNode) currentAST.root);
					if (currentAST.child == null)
					{
						// Add new child to current root
						currentAST.root.setFirstChild(child);
						((ASTNode) child).setPreviousSibling(null);
					}
					else
					{
						currentAST.child.setNextSibling(child);
						((ASTNode) child).setPreviousSibling((ASTNode) currentAST.child);
					}
				}
				// Make new child the current child
				currentAST.child = child;
				currentAST.advanceChildToEnd();
			}
		}
		
		/// <summary>
		/// Duplicate AST Node tree rooted at specified AST node and all of it's siblings.
		/// </summary>
		/// <param name="t">Root of AST Node tree.</param>
		/// <returns>Root node of new AST Node tree (or null if <c>t</c> is null).</returns>
		public override AST dupList(AST t)
		{
			AST result = dupTree(t); // if t == null, then result==null
			AST nt = result;
			while (t != null)
			{
				// for each sibling of the root
				t = t.getNextSibling();
				AST d = dupTree(t);
				nt.setNextSibling(d); // dup each subtree, building new tree
				if (d != null) ((ASTNode) d).setPreviousSibling((ASTNode) nt);
				nt = nt.getNextSibling();
			}
			return result;
		}
		
		/// <summary>
		/// Duplicate AST Node tree rooted at specified AST node. Ignore it's siblings.
		/// </summary>
		/// <param name="t">Root of AST Node tree.</param>
		/// <returns>Root node of new AST Node tree (or null if <c>t</c> is null).</returns>
		public override AST dupTree(AST t)
		{
			AST result = dup(t); // make copy of root
			// copy all children of root.
			if (t != null)
			{
				AST d = dupList(t.getFirstChild());
				result.setFirstChild(d);
				if (d != null) ((ASTNode) d).setParent((ASTNode) result);
			}
			return result;
		}
		
		/// <summary>
		/// Make a tree from a list of nodes.  The first element in the
		/// array is the root.  If the root is null, then the tree is
		/// a simple list not a tree.  Handles null children nodes correctly.
		/// For example, build(a, b, null, c) yields tree (a b c).  build(null,a,b)
		/// yields tree (nil a b).
		/// </summary>
		/// <param name="nodes">List of Nodes.</param>
		/// <returns>AST Node tree.</returns>
		public override AST make(params AST[] nodes)
		{
			if (nodes == null || nodes.Length == 0)
				return null;
			AST root = nodes[0];
			AST tail = null;
			if (root != null)
			{
				root.setFirstChild(null); // don't leave any old pointers set
			}
			// link in children;
			for (int i = 1; i < nodes.Length; i++)
			{
				if (nodes[i] == null)
					continue;
				// ignore null nodes
				if (root == null)
				{
					// Set the root and set it up for a flat list
					root = (tail = nodes[i]);
				}
				else if (tail == null)
				{
					root.setFirstChild(nodes[i]);
					((ASTNode) nodes[i]).setParent((ASTNode) root);
					tail = root.getFirstChild();
				}
				else
				{
					((ASTNode) nodes[i]).setParent((ASTNode) root);
					tail.setNextSibling(nodes[i]);
					((ASTNode) nodes[i]).setPreviousSibling((ASTNode) tail);
					tail = tail.getNextSibling();
				}
				// Chase tail to last sibling
				while (tail.getNextSibling() != null)
				{
					tail = tail.getNextSibling();
				}
			}
			return root;
		}
		
		/// <summary>
		/// Make an AST the root of current AST.
		/// </summary>
		/// <param name="currentAST"></param>
		/// <param name="root"></param>
		public override void  makeASTRoot(ref ASTPair currentAST, AST root)
		{
			if (root != null)
			{
				// Add the current root as a child of new root
				((ASTNode) root).addChildEx((ASTNode) currentAST.root);
				// The new current child is the last sibling of the old root
				currentAST.child = currentAST.root;
				currentAST.advanceChildToEnd();
				// Set the new root
				currentAST.root = root;
			}
		}

		public override AST create()
		{
			ASTNode newNode = (ASTNode) base.create();
			newNode.File = filefinfo_;
			return newNode;
		}
		
		public override AST create(int type)
		{
			ASTNode newNode = (ASTNode) base.create(type);
			newNode.File = filefinfo_;
			return newNode;
		}
		
		public override AST create(int type, string txt)
		{
			ASTNode newNode = (ASTNode) base.create(type, txt);
			newNode.File = filefinfo_;
			return newNode;
		}
		
		public override AST create(int type, string txt, string ASTNodeTypeName)
		{
			ASTNode newNode = (ASTNode) base.create(type, txt, ASTNodeTypeName);
			newNode.File = filefinfo_;
			return newNode;
		}
	}
}