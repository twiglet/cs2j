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
	{ Debug("start"); } using_directives
	;

using_directives:
    ^(USING_DIRECTIVE 'using'  namespace_name ';' { Debug("using " + $namespace_name.namespaceText); }) 
	;

namespace_name returns [string namespaceText]:
    ^(NAMESPACE_OR_TYPE_NAME nsc=namespace_component { namespaceText = $nsc.idText; } 
	                         (nscp=namespace_component { namespaceText = namespaceText + "." + $nscp.idText; } )* )  
	;
	
namespace_component returns [string idText]:
    ^(NSTN identifier { idText=$identifier.idText; } ) 
	;

identifier returns [string idText]:
    ^(ID IDENTIFIER { idText = $IDENTIFIER.Text; Debug("Identifier: " + $IDENTIFIER.Text); } )
	;

