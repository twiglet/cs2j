using System;
//using RusticiSoftware.Translator;
using OldTSpace = RusticiSoftware.Translator;
using NewTSpace = RusticiSoftware.Translator.CLR;
using System.Collections.Generic;

namespace UpdateTxFiles
{
	public class UpdateTranslationTemplate {
		
		private OldTSpace.TypeRepTemplate inProgress = null;
		
		public UpdateTranslationTemplate ()
		{
		}
		
		public void upgrade(OldTSpace.TranslationBase inV, NewTSpace.TranslationBase outV) {
			outV.SurroundingTypeName = inProgress.TypeName;
			// Nothing else to do,  OldTSpace.TranslationBase has nothing
		}
		
		public void upgrade(OldTSpace.ParamRepTemplate inV, NewTSpace.ParamRepTemplate outV) {
			outV.Type = inV.Type;
			outV.Name = inV.Name;
		}

		public void upgrade(string inV, NewTSpace.UseRepTemplate outV) {
			outV.Namespace = inV;
		}

		public void upgrade(OldTSpace.ConstructorRepTemplate inV, NewTSpace.ConstructorRepTemplate outV) {
			
			upgrade(inV as OldTSpace.TranslationBase, outV as NewTSpace.TranslationBase);
	
			outV.Imports = inV.Imports;	
			if (!String.IsNullOrEmpty(inV.Java))
				outV.Java = inV.Java;			
			
			foreach (OldTSpace.ParamRepTemplate inP in inV.Params) {			
				NewTSpace.ParamRepTemplate outP = new NewTSpace.ParamRepTemplate();
				upgrade(inP, outP);
				outV.Params.Add(outP);
			}				
		}
		
		public void upgrade(OldTSpace.FieldRepTemplate inV, NewTSpace.FieldRepTemplate outV) {
			
			upgrade(inV as OldTSpace.TranslationBase, outV as NewTSpace.TranslationBase);
	
			outV.Imports = inV.Imports;	
			outV.Type = inV.Type;
			outV.Name = inV.Name;
			
			if (!String.IsNullOrEmpty(inV.Get))
				outV.Java = inV.Get;			
		}
		
		public void upgrade(OldTSpace.PropRepTemplate inV, NewTSpace.PropRepTemplate outV) {
			
			upgrade(inV as OldTSpace.FieldRepTemplate, outV as NewTSpace.FieldRepTemplate);
	
			if (!String.IsNullOrEmpty(inV.Get))
				outV.JavaGet = inV.Get;			
		
			if (!String.IsNullOrEmpty(inV.Set))
				outV.JavaSet = inV.Set;			
		
		}
		
		public void upgrade(OldTSpace.CastRepTemplate inV, NewTSpace.CastRepTemplate outV) {
			
			upgrade(inV as OldTSpace.TranslationBase, outV as NewTSpace.TranslationBase);
	
			outV.Imports = inV.Imports;	
			outV.From = inV.From;
			outV.To = inV.To;
			
			if (!String.IsNullOrEmpty(inV.Java))
				outV.Java = inV.Java;			
		}
		
		public void upgrade(OldTSpace.MethodRepTemplate inV, NewTSpace.MethodRepTemplate outV) {
			
			upgrade(inV as OldTSpace.ConstructorRepTemplate, outV as NewTSpace.ConstructorRepTemplate);
	
			outV.Name = inV.Name;
			outV.Return = inV.Return ?? "System.Void";
			
		}
		
		public void upgrade(OldTSpace.TypeRepTemplate inV, NewTSpace.TypeRepTemplate outV) {
			
			upgrade(inV as OldTSpace.TranslationBase, outV as NewTSpace.TranslationBase);
	
			outV.TypeName = inV.TypeName;
			
			List<NewTSpace.UseRepTemplate> uses = new List<NewTSpace.UseRepTemplate>();
			foreach (string inU in inV.NamespacePath) {			
				NewTSpace.UseRepTemplate outU = new NewTSpace.UseRepTemplate();
				upgrade(inU, outU);
				uses.Add(outU);
			}		

			outV.Uses = uses.ToArray();
		}
		
		public void upgrade(OldTSpace.TypeRepTemplate inV, NewTSpace.InterfaceRepTemplate outV) {
			
			upgrade(inV as OldTSpace.TranslationBase, outV as NewTSpace.TranslationBase);
	
			outV.Inherits = inV.Inherits;
			if (!String.IsNullOrEmpty(inV.Java))
				outV.Java = inV.Java;			
			
			
			foreach (OldTSpace.MethodRepTemplate inM in inV.Methods) {			
				NewTSpace.MethodRepTemplate outM = new NewTSpace.MethodRepTemplate();
				upgrade(inM, outM);
				outV.Methods.Add(outM);
			}		

			foreach (OldTSpace.PropRepTemplate inP in inV.Properties) {			
				NewTSpace.PropRepTemplate outP = new NewTSpace.PropRepTemplate();
				upgrade(inP, outP);
				outV.Properties.Add(outP);
			}		

		}
		
		public void upgrade(OldTSpace.ClassRepTemplate inV, NewTSpace.ClassRepTemplate outV) {
			upgrade(inV as OldTSpace.TypeRepTemplate, outV as NewTSpace.InterfaceRepTemplate);
		
			foreach (OldTSpace.ConstructorRepTemplate inC in inV.Constructors) {			
				NewTSpace.ConstructorRepTemplate outC = new NewTSpace.ConstructorRepTemplate();
				upgrade(inC, outC);
				outV.Constructors.Add(outC);
			}		
			foreach (OldTSpace.FieldRepTemplate inF in inV.Fields) {			
				NewTSpace.FieldRepTemplate outF = new NewTSpace.FieldRepTemplate();
				upgrade(inF, outF);
				outV.Fields.Add(outF);
			}		
			foreach (OldTSpace.CastRepTemplate inC in inV.Casts) {			
				NewTSpace.CastRepTemplate outC = new NewTSpace.CastRepTemplate();
				upgrade(inC, outC);
				outV.Casts.Add(outC);
			}		
			
		}
		
		public void upgrade(OldTSpace.StructRepTemplate inV, NewTSpace.StructRepTemplate outV) {
			upgrade(inV, outV);
		}
		
		public NewTSpace.TypeRepTemplate upgrade (OldTSpace.TypeRepTemplate inTemplate)
		{
			inProgress = inTemplate;
			
			OldTSpace.StructRepTemplate strukt = inTemplate as OldTSpace.StructRepTemplate;
			if (strukt != null) {
			    NewTSpace.StructRepTemplate res = new NewTSpace.StructRepTemplate();
				upgrade(strukt, res);
				return res;
			}
			OldTSpace.ClassRepTemplate klass = inTemplate as OldTSpace.ClassRepTemplate;
			if (klass != null) {
			    NewTSpace.ClassRepTemplate res = new NewTSpace.ClassRepTemplate();
				upgrade(klass, res);
				return res;
			}
			OldTSpace.InterfaceRepTemplate iface = inTemplate as OldTSpace.InterfaceRepTemplate;
			if (iface != null) {
			    NewTSpace.InterfaceRepTemplate res = new NewTSpace.InterfaceRepTemplate();
				upgrade(iface, res);
				return res;
			}

			throw new System.NotImplementedException(inTemplate.GetType().ToString());
		}
	
	}
}

