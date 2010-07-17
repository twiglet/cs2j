// SignatureExtracter.g
//
// Crawler that extracts the signatures (typereptemplates) from a CSharp AST 
//
// Kevin Glynn
// kevin.glynn@twigletsoftware.com
// June 2010
  
tree grammar SignatureExtracter;

options {
    tokenVocab=cs;
    ASTLabelType=CommonTree;
	language=CSharp2;
	superClass='RusticiSoftware.Translator.CSharp.CommonWalker';
	//backtrack=true;
}

@namespace { RusticiSoftware.Translator.CSharp }

@header
{
	using System.Text;
	using RusticiSoftware.Translator.CLR;
}

@members 
{
        // As we scan the AST we collect these features until
		// we reach the end, then calculate the TypeRep and insert it into 
		// the TypeEnv  
        private IList<PropRepTemplate> Properties = new List<PropRepTemplate>();
        private IList<MethodRepTemplate> Methods = new List<MethodRepTemplate>();
		private IList<ConstructorRepTemplate> Constructors = new List<ConstructorRepTemplate>();
        private IList<FieldRepTemplate> Fields = new List<FieldRepTemplate>();
        private IList<CastRepTemplate> Casts = new List<CastRepTemplate>();
}

/********************************************************************************************
                          Parser section
*********************************************************************************************/

///////////////////////////////////////////////////////
compilation_unit: 
	{ Debug("Debug: start"); } using_directives
	;

using_directives:
    ^(USING_DIRECTIVE 'using' { Console.Out.WriteLine("Debug: using"); } namespace_name ';') 
	;

namespace_name:
    ^(NAMESPACE_OR_TYPE_NAME namespace_component) 
	;
	
namespace_component:
    ^(NSTN identifier)
	;

identifier:
    ^(ID id=IDENTIFIER { Console.Out.WriteLine("Identifier: " + id.Text);})
	;

