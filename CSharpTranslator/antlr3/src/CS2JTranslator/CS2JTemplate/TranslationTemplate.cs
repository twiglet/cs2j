/*
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using System.IO;
using System.Xml;
using System.Xml.Serialization;
using Twiglet.CS2J.Translator.Utils;

// These Template classes are in-memory versions of the xml translation templates
// (we use C# to directly persist to / from files).

// We have overloaded Equals to test value equality for these template objects.  For now its only 
// used by unit tests (to check that the object survives xml serialization / deserialization
// unscathed). But it might be useful down the road.
// By overloading Equals, we also have to overload GetHashCode (well, its highly reccomended)...

namespace Twiglet.CS2J.Translator.TypeRep
{
   
   public class TemplateUtilities
   {
            
      public static string Substitute(string c, Dictionary<string,TypeRepTemplate> argMap)
      {
         String ret = c;
         if (argMap.ContainsKey(c))
         {
            ret = argMap[c].TypeName;
         }
         return ret;
      }
      
      public static string SubstituteInType(String type, Dictionary<string,TypeRepTemplate> argMap)
      {
         if (String.IsNullOrEmpty(type))
            return type;

         string ret = type;
         // type is either "string" or "string<type,type,...>"
         Match match = Regex.Match(type, @"^([\w|\.]+)(?:\s*\[\s*([\w|\.]+)(?:\s*,\s*([\w|\.]+))*\s*\])?$");
         if (match.Success)
         {
            CaptureCollection captures = match.Captures;
            StringBuilder buf = new StringBuilder();
            buf.Append(Substitute(captures[0].Value, argMap));
            if ( captures.Count > 1)
            {
               bool first = true;
               buf.Append("[");
               for (int i = 1; i < captures.Count; i++)
               {
                  if (!first)
                  {
                     buf.Append(", ");
                  }
                  buf.Append(Substitute(captures[i].Value, argMap));
                  first = false;
               }
               buf.Append("]");
            }
            ret = buf.ToString();
         }
         return ret;
      }
   }

   public interface IApplyTypeArgs
   {
      // Instantiate type arguments "in-situ"
      void Apply(Dictionary<string,TypeRepTemplate> args);
   }

   public enum Javastyle 
   {
      Clean, MarkAuto
   }
	
   // Simple <type> <name> pairs to represent formal parameters
   public class ParamRepTemplate : IEquatable<ParamRepTemplate>, IApplyTypeArgs
   {
      private string _type;
      public string Type { 
         get { return _type; }
         set {
            _type=value.Replace("<","*[").Replace(">","]*");
         }
      }
      public string Name { get; set; }

      // ref or out param?
      [XmlAttribute("byref")]
      [System.ComponentModel.DefaultValueAttribute(false)]
      public bool IsByRef{ get; set; }

      public ParamRepTemplate ()
      {
         IsByRef = false;
      }

      public ParamRepTemplate(ParamRepTemplate copyFrom)
      {

         if (!String.IsNullOrEmpty(copyFrom.Type))
         {
            Type = copyFrom.Type;
         }
         if (!String.IsNullOrEmpty(copyFrom.Name))
         {
            Name = copyFrom.Name;
         }
         IsByRef = copyFrom.IsByRef;
      }

      public ParamRepTemplate (string t, string a)
      {
         Type = t;
         Name = a;
         IsByRef = false;
      }

      public ParamRepTemplate (string t, string a, bool isbyref)
      {
         Type = t;
         Name = a;
         IsByRef = isbyref;
      }

      public void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         Type = TemplateUtilities.SubstituteInType(Type, args);
      }

      #region Equality
      public bool Equals (ParamRepTemplate other)
      {
         if (other == null)
            return false;
			
         return Type == other.Type && Name == other.Name && IsByRef == other.IsByRef;
      }

      public override bool Equals (object obj)
      {
			
         ParamRepTemplate temp = obj as ParamRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (ParamRepTemplate a1, ParamRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (ParamRepTemplate a1, ParamRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         return (Type ?? String.Empty).GetHashCode () ^ (Name ?? String.Empty).GetHashCode () ^ IsByRef.GetHashCode();
      }
      #endregion
   }

   // A namespace alias entry.
   public class AliasRepTemplate : IEquatable<AliasRepTemplate>
   {

      public string Alias { get; set; }
      public string Namespace { get; set; }


      public AliasRepTemplate()
      {
         Alias = null;
         Namespace = null;
      }

      public AliasRepTemplate(AliasRepTemplate copyFrom)
      {

         if (!String.IsNullOrEmpty(copyFrom.Alias))
         {
            Alias = copyFrom.Alias;
         }
         if (!String.IsNullOrEmpty(copyFrom.Namespace))
         {
            Namespace = copyFrom.Namespace;
         }
      }

      public AliasRepTemplate (string a, string u)
      {
         Alias = a;
         Namespace = u;
      }

      #region Equality
      public bool Equals (AliasRepTemplate other)
      {
         if (other == null)
            return false;
			
         return Alias == other.Alias && Namespace == other.Namespace;
      }

      public override bool Equals (object obj)
      {
			
         AliasRepTemplate temp = obj as AliasRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (AliasRepTemplate a1, AliasRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (AliasRepTemplate a1, AliasRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         return (Alias ?? String.Empty).GetHashCode () ^ (Namespace ?? String.Empty).GetHashCode ();
      }
      #endregion
		
   }


   // Never directly create a TranslationBase. Its a common root for translatable language entities
   public abstract class TranslationBase : IEquatable<TranslationBase>, IApplyTypeArgs
   {
      // Java imports required to make Java translation run
      private string[] _imports = null;
      [XmlArrayItem("Import")]
      public virtual string[] Imports { 
         get {
            // if _java is not set then see if we have default imports, otherwise
            // assume imports is already correctly (un)set
            if (_imports == null && _java == null) {
               return mkImports();
            }
            return _imports;
         }
         set { _imports = value; } 
      }
		
      // The Java translation for this C# entity
      protected string _java = null; 		
      public virtual string Java { 
         get { 
            if (_java == null) {
               return mkJava();
            } 
            else {
               return _java;
            }
         }
         set { _java = value; } 
      }
		
      // Optional,  but if present will let mkJava generate better java guess in some cases
      private string _surroundingTypeName;
      [XmlIgnore]
      public string SurroundingTypeName { 
         get { return _surroundingTypeName; }
         set {
            _surroundingTypeName=value.Replace("<","*[").Replace(">","]*");
         }
      }		
      public virtual string[] mkImports() {
         return null;
      }
		
      public string[] mkImports(Javastyle style) {
         string[] imports = mkImports();
         if (style == Javastyle.MarkAuto) {
            for (int i = 0; i < imports.Length; i++) {
               imports[i] = imports[i] + " /*auto*/";
            }
         }
         return imports;
      }

      public abstract string mkJava(); 
		
      public string mkJava(Javastyle style) {
         string unAdornedJava = mkJava();
         if (style == Javastyle.MarkAuto) {
            return "/*auto (/*" + unAdornedJava + "/*)*/";
         }
         else {
            return unAdornedJava;
         }
      }

      protected TranslationBase()
      {
         Imports = null;
      }

      protected TranslationBase(TranslationBase copyFrom)
      {
         int len = 0;
         if (copyFrom.Imports != null)
         {
            len = copyFrom.Imports.Length;
            Imports = new String[len];
            for (int i = 0; i < len; i++)
            {
               Imports[i] = copyFrom.Imports[i];
            }
         }
         if (!String.IsNullOrEmpty(copyFrom.Java))
         {
            Java = copyFrom.Java;
         }
         if (!String.IsNullOrEmpty(copyFrom.SurroundingTypeName))
         {
            SurroundingTypeName = copyFrom.SurroundingTypeName;
         }
      }

      protected TranslationBase(string java)
      {
         Imports = null;
         Java = java;
      }

      protected TranslationBase (string[] imps, string java)
      {
         Imports = imps;
         Java = java;
      }


      protected string mkJavaParams(IList<ParamRepTemplate> pars) {
         StringBuilder parStr = new StringBuilder();
         parStr.Append("(");
         foreach (ParamRepTemplate p in pars) {
            parStr.Append("${"+p.Name+"},");
         }
         if (parStr[parStr.Length-1] == ',') {
            parStr.Remove(parStr.Length-1,1);
         }
         parStr.Append(")");
         return parStr.ToString();
      }


      // Instantiate type arguments
      public virtual void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         if (!String.IsNullOrEmpty(SurroundingTypeName))
         {
            SurroundingTypeName = TemplateUtilities.SubstituteInType(SurroundingTypeName, args);
         }
      }

      #region Equality

      public bool Equals (TranslationBase other)
      {
         if (other == null)
            return false;
			
         if (Imports != other.Imports) {
            if (Imports == null || other.Imports == null || Imports.Length != other.Imports.Length)
               return false;
            for (int i = 0; i < Imports.Length; i++) {
               if (Imports[i] != other.Imports[i])
                  return false;
            }
         }
			
         return Java == other.Java;
      }

      public override bool Equals (object obj)
      {
			
         TranslationBase temp = obj as TranslationBase;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (TranslationBase a1, TranslationBase a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (TranslationBase a1, TranslationBase a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         int hashCode = 0;
         if (Imports != null) {
            foreach (string e in Imports) {
               hashCode ^= e.GetHashCode();
            }
         }
         return (Java ?? String.Empty).GetHashCode () ^ hashCode;
      }
      #endregion
		
   }
   
   public class IterableRepTemplate : TranslationBase, IEquatable<IterableRepTemplate>
   {

      public String ElementType {
         get; set;
      }
		
      public override string mkJava() {
         return "${expr}";
      }
		
      public IterableRepTemplate () : base()
      {
      }

      public IterableRepTemplate(String ty)
         : base()
      {
         ElementType = ty;
      }

      public IterableRepTemplate(IterableRepTemplate copyFrom)
         : base(copyFrom)
      {
         if (!String.IsNullOrEmpty(copyFrom.ElementType))
         {
            ElementType = copyFrom.ElementType;
         }
      }

      public IterableRepTemplate (String ty, string[] imps, string javaRep) : base(imps, javaRep)
      {
         ElementType = ty;
      }


      public override void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         if (ElementType != null)
         {
            ElementType = TemplateUtilities.SubstituteInType(ElementType, args);
         }
         base.Apply(args);
      }

      #region Equality

      public bool Equals (IterableRepTemplate other)
      {
         if (other == null)
            return false;
			
         return ElementType == other.ElementType && base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         IterableRepTemplate temp = obj as IterableRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (IterableRepTemplate a1, IterableRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (IterableRepTemplate a1, IterableRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {	
         return base.GetHashCode () ^ ElementType.GetHashCode();
      }
      #endregion
   }

   public class ConstructorRepTemplate : TranslationBase, IEquatable<ConstructorRepTemplate>
   {

      private List<ParamRepTemplate> _params = null;
      [XmlArrayItem("Param")]
      public List<ParamRepTemplate> Params {
         get {
            if (_params == null)
               _params = new List<ParamRepTemplate> ();
            return _params;
         }
      }
		
      public override string mkJava() {
         string constructorName = "CONSTRUCTOR";
         if (!String.IsNullOrEmpty(SurroundingTypeName)) {
            constructorName = SurroundingTypeName.Substring(SurroundingTypeName.LastIndexOf('.') + 1);
         }
         return "new " + constructorName + mkJavaParams(Params);
      }
		
      public override string[] mkImports() {
         if (!String.IsNullOrEmpty(SurroundingTypeName)) {
            return new string[] {SurroundingTypeName};
         }
         else {
            return null;
         }
      }

      public ConstructorRepTemplate()
         : base()
      {
      }

      public ConstructorRepTemplate(ConstructorRepTemplate copyFrom)
         : base(copyFrom)
      {
         foreach (ParamRepTemplate p in copyFrom.Params)
         {
            Params.Add(new ParamRepTemplate(p));
         }
      }

      public ConstructorRepTemplate (List<ParamRepTemplate> pars) : base()
      {
         _params = pars;
      }

      public ConstructorRepTemplate (List<ParamRepTemplate> pars, string[] imps, string javaRep) : base(imps, javaRep)
      {
         _params = pars;
      }


      public override void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         if (Params != null)
         {
            foreach(ParamRepTemplate p in Params)
            {
               p.Apply(args);
            }
         }
         base.Apply(args);
      }

      #region Equality

      public bool Equals (ConstructorRepTemplate other)
      {
         if (other == null)
            return false;
			
         if (Params != other.Params) {
            if (Params == null || other.Params == null || Params.Count != other.Params.Count)
               return false;
            for (int i = 0; i < Params.Count; i++) {
               if (Params[i] != other.Params[i])
                  return false;
            }
         }

         return base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         ConstructorRepTemplate temp = obj as ConstructorRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (ConstructorRepTemplate a1, ConstructorRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (ConstructorRepTemplate a1, ConstructorRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         int hashCode = 0;
         foreach (ParamRepTemplate o in Params) {
            hashCode = hashCode ^ o.GetHashCode() ;
         }
			
         return base.GetHashCode () ^ hashCode;
      }
      #endregion
   }

   // Method has the same info as a delegate as a constructor plus a name and return type
   public class MethodRepTemplate : ConstructorRepTemplate, IEquatable<ConstructorRepTemplate>
   {
      // Method name
      public string Name { get; set; }

      private string[] _typeParams = null;
      [XmlArrayItem("Name")]
      public string[] TypeParams { 
         get
         {
            if (_typeParams == null)
            {
               TypeParams = new string[0];
            }
            return _typeParams;
         }
         set
         {
            // First time that TypeParams is set then create InstantiatedTypes as corresponding list of TypeVars 
            if (value != null && InstantiatedTypes == null)
            {
               InstantiatedTypes = new TypeRepTemplate[value.Length];
               for (int i = 0; i < value.Length; i++)
               {
                  InstantiatedTypes[i] = new TypeVarRepTemplate(value[i]);
               }
            }
            _typeParams = value;
         }
      }

      [XmlIgnore]
      public TypeRepTemplate[] InstantiatedTypes { get; set; }

      // Return type
      private string _return;
      public string Return { 
         get { return _return; }
         set {
            _return=value.Replace("<","*[").Replace(">","]*");
         }
      }		

      // isStatic method?
      [XmlAttribute("static")]
      [System.ComponentModel.DefaultValueAttribute(false)]
      public bool IsStatic{ get; set; }

      public MethodRepTemplate()
      {
         IsStatic = false;
      }

      public MethodRepTemplate(MethodRepTemplate copyFrom) : base(copyFrom)
      {
         if (!String.IsNullOrEmpty(copyFrom.Name))
         {
            Name = copyFrom.Name;
         }
         int len = 0;
         if (copyFrom.TypeParams != null)
         {
            len = copyFrom.TypeParams.Length;
            TypeParams = new String[len];
            for (int i = 0; i < len; i++)
            {
               TypeParams[i] = copyFrom.TypeParams[i];
            }
         }
         if (copyFrom.InstantiatedTypes != null)
         {
            len = copyFrom.InstantiatedTypes.Length;
            InstantiatedTypes = new TypeRepTemplate[len];
            for (int i = 0; i < len; i++)
            {
               InstantiatedTypes[i] = copyFrom.InstantiatedTypes[i].Instantiate(null);
            }
         }
         if (!String.IsNullOrEmpty(copyFrom.Return))
         {
            Return = copyFrom.Return;
         }

         IsStatic = copyFrom.IsStatic;
      }

      public MethodRepTemplate(string retType, string methodName, string[] tParams, List<ParamRepTemplate> pars, string[] imps, string javaRep)
         : base(pars, imps, javaRep)
      {
         Name = methodName;
         TypeParams = tParams;
         Return = retType;
         IsStatic = false;
      }

      public MethodRepTemplate (string retType, string methodName, string[] tParams, List<ParamRepTemplate> pars) : this(retType, methodName, tParams, pars, null, null)
      {
      }
		
      public override string[] mkImports() {
         if (IsStatic && SurroundingTypeName != null) {
            return new string[] {SurroundingTypeName};
         }
         else {
            return null;
         }
      }	
		
      public override string mkJava() {
         StringBuilder methStr = new StringBuilder();
         if (IsStatic) {
            if (!String.IsNullOrEmpty(SurroundingTypeName)) {
               methStr.Append(SurroundingTypeName.Substring(SurroundingTypeName.LastIndexOf('.') + 1) + ".");
            }
            else {
               methStr.Append("TYPENAME.");
            }
         }
         else {
            methStr.Append("${this:16}.");
         }
         // special for ToString -> tostring
         if (Name == "ToString" && Params.Count == 0)
         {
            methStr.Append("toString");
         }  
         else
         {
            methStr.Append(Name);
         }
         return methStr.ToString() + mkJavaParams(Params);
      }
		
      // TODO: filter out redefined type names
      public override void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         if (Return != null)
         {
            Return = TemplateUtilities.SubstituteInType(Return,args);
         }
         base.Apply(args);
      }

      #region Equality
      public bool Equals (MethodRepTemplate other)
      {
         if (other == null)
            return false;

         if (TypeParams != other.TypeParams) {
            if (TypeParams == null || other.TypeParams == null || TypeParams.Length != other.TypeParams.Length)
               return false;
            for (int i = 0; i < TypeParams.Length; i++) {
               if (TypeParams[i] != other.TypeParams[i])
                  return false;
            }
         }
         if (InstantiatedTypes != other.InstantiatedTypes) {
            if (InstantiatedTypes == null || other.InstantiatedTypes == null || InstantiatedTypes.Length != other.InstantiatedTypes.Length)
               return false;
            for (int i = 0; i < InstantiatedTypes.Length; i++) {
               if (InstantiatedTypes[i] != other.InstantiatedTypes[i])
                  return false;
            }
         }
			
         return Return == other.Return && Name == other.Name && IsStatic == other.IsStatic && base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         MethodRepTemplate temp = obj as MethodRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (MethodRepTemplate a1, MethodRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (MethodRepTemplate a1, MethodRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         int hashCode = 0;
         if (TypeParams != null) {
            foreach (string o in TypeParams) {
               hashCode = hashCode ^ o.GetHashCode() ;
            }
         }
         if (InstantiatedTypes != null) {
            foreach (TypeRepTemplate o in InstantiatedTypes) {
               hashCode = hashCode ^ o.GetHashCode() ;
            }
         }

         return hashCode ^ (Return ?? String.Empty).GetHashCode () ^ (Name ?? String.Empty).GetHashCode () ^ IsStatic.GetHashCode() ^ base.GetHashCode();
      }
      #endregion

   }

   //  A user-defined cast from one type to another
   public class CastRepTemplate : TranslationBase, IEquatable<CastRepTemplate>
   {
      // From and To are fully qualified types
      private string _from;
      public string From { 
         get { return _from; }
         set {
            _from=value.Replace("<","*[").Replace(">","]*");
         }
      }		

      private string _to;
      public string To { 
         get { return _to; }
         set {
            _to=value.Replace("<","*[").Replace(">","]*");
         }
      }


      public CastRepTemplate()
         : base()
      {
      }

      public CastRepTemplate(CastRepTemplate copyFrom)
         : base(copyFrom)
      {
         if (!String.IsNullOrEmpty(copyFrom.From))
         {
            From = copyFrom.From;
         }
         if (!String.IsNullOrEmpty(copyFrom.To))
         {
            To = copyFrom.To;
         }

      }

      public CastRepTemplate (string fType, string tType, string[] imps, string java) : base(imps, java)
      {
         From = fType;
         To = tType;
      }

      public CastRepTemplate (string fType, string tType) : this(fType, tType, null, null)
      {
      }
		
      public override string[] mkImports() {
         if (!String.IsNullOrEmpty(SurroundingTypeName)) {
            return new string[] {SurroundingTypeName};
         }
         else {
            return null;
         }
      }	
		
      public override string mkJava() {
         if (From == null || To == null) {
            return null;
         }
         else {
            if (!String.IsNullOrEmpty(SurroundingTypeName)) {
               String myType = SurroundingTypeName.Substring(SurroundingTypeName.LastIndexOf('.') + 1);
               String toType = To.Substring(To.LastIndexOf('.') + 1);
               if (myType == toType)
               {
                  // just overload various casts to my type
                  return  myType + ".__cast(${expr})";
               }
               else
               {
                  return  myType + ".__cast${TYPEOF_totype}(${expr})";                                        
               }
            }
            else
            {
               return "__cast_" + To.Replace('.','_') + "(${expr})";
            }
         }
      }

      public override void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         if (From != null)
         {
            From = TemplateUtilities.SubstituteInType(From, args);
         }
         if (To != null)
         { 
            To = TemplateUtilities.SubstituteInType(To, args);
         }
         base.Apply(args);
      }

      #region Equality
      public bool Equals (CastRepTemplate other)
      {
         if (other == null)
            return false;
			
         return From == other.From && To == other.To && base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         CastRepTemplate temp = obj as CastRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (CastRepTemplate a1, CastRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (CastRepTemplate a1, CastRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         return (From ?? String.Empty).GetHashCode() ^ (To ?? String.Empty).GetHashCode() ^ base.GetHashCode();
      }
      #endregion
		
   }

   // A member field definition
   public class FieldRepTemplate : TranslationBase, IEquatable<FieldRepTemplate>
   {

      private string _type;
      public string Type { 
         get { return _type; }
         set {
            _type=value.Replace("<","*[").Replace(">","]*");
         }
      }		
      public string Name { get; set; }

      public FieldRepTemplate()
         : base()
      {
      }

      public FieldRepTemplate(FieldRepTemplate copyFrom)
         : base(copyFrom)
      {
         if (!String.IsNullOrEmpty(copyFrom.Name))
         {
            Name = copyFrom.Name;
         }
         if (!String.IsNullOrEmpty(copyFrom.Type))
         {
            Type = copyFrom.Type;
         }
      }

      public FieldRepTemplate(string fType, string fName, string[] imps, string javaGet)
         : base(imps, javaGet)
      {
         Type = fType;
         Name = fName;
      }

      public FieldRepTemplate (string fType, string fName) : this(fType, fName, null, null)
      {
      }
		
				
      public override string mkJava() {
         return "${this:16}." + Name;
      }

      public override void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         if (Type != null)
         {
            Type = TemplateUtilities.SubstituteInType(Type, args);
         }
         base.Apply(args);
      }

      #region Equality
         public bool Equals (FieldRepTemplate other)
      {
         if (other == null)
            return false;
			
         return Type == other.Type && Name == other.Name && base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         FieldRepTemplate temp = obj as FieldRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (FieldRepTemplate a1, FieldRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (FieldRepTemplate a1, FieldRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         return (Type ?? String.Empty).GetHashCode() ^ (Name ?? String.Empty).GetHashCode() ^ base.GetHashCode();
      }
      #endregion
		
   }

   // A property definition.  We need separate java translations for getter and setter.  If JavaGet is null
   // then we can use Java (from TranslationBase) as the translation for gets.
   // Imports are shared between getter and setter (might lead to some unneccessary extra imports, but I'm
   // guessing that normally imports will be the same for both)
   public class PropRepTemplate : FieldRepTemplate, IEquatable<PropRepTemplate>
   {
      protected string _javaGet = null;		
      [XmlElementAttribute("Get")]
      public virtual string JavaGet {
         get {
            if (!CanRead) return null;
            if (_javaGet == null) {
               if (_java == null) {
                  return (CanRead ? "${this:16}.get" + Name + "()" : null);
               }
               else {
                  return _java;
               }
            }
            else {
               return _javaGet;
            }
         }
         set { _javaGet = value; }
      }
                
      public override string Java
      {
         get
         {
            return JavaGet;
         }
      }

      protected string _javaSet = null;
      [XmlElementAttribute("Set")]
      public virtual string JavaSet { 
         get {
            if (_javaSet == null) {
               return (CanWrite ? "${this:16}.set" + Name + "(${value})" : null);
            }
            else {
               return _javaSet;
            }
         }
         set { _javaSet = value; }
      }
		
      // canRead?
      private bool _canRead = true;
      [XmlAttribute("read")]
      [System.ComponentModel.DefaultValueAttribute(true)]
      public bool CanRead { 
         get { return _canRead; }
         set { _canRead = value; }
      }
		
      // canWrite?
      private bool _canWrite = true;
      [XmlAttribute("write")]
      [System.ComponentModel.DefaultValueAttribute(true)]
      public bool CanWrite { 
         get { return _canWrite; }
         set { _canWrite = value; }
      }

      public PropRepTemplate()
         : base()
      {
      }

      public PropRepTemplate(PropRepTemplate copyFrom)
         : base(copyFrom)
      {
         if (!String.IsNullOrEmpty(copyFrom.JavaGet))
         {
            JavaGet = copyFrom.JavaGet;
         }
         if (!String.IsNullOrEmpty(copyFrom.JavaSet))
         {
            JavaSet = copyFrom.JavaSet;
         }
         CanRead = copyFrom.CanRead;
         CanWrite = copyFrom.CanWrite;
      }

      public PropRepTemplate(string fType, string fName, string[] imps, string javaGet, string javaSet)
         : base(fType, fName, imps, null)
      {
         JavaGet = javaGet;
         JavaSet = javaSet;
      }

      public PropRepTemplate (string fType, string fName) : this(fType, fName, null, null, null)
      {
      }
		
      public override string mkJava ()
      {
         // favour JavaGet
         return null;
      }
		
      #region Equality
      public bool Equals (PropRepTemplate other)
      {
         if (other == null)
            return false;
			
         return JavaGet == other.JavaGet && JavaSet == other.JavaSet && base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         PropRepTemplate temp = obj as PropRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (PropRepTemplate a1, PropRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (PropRepTemplate a1, PropRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         return (JavaGet ?? String.Empty).GetHashCode () ^ (JavaSet ?? String.Empty).GetHashCode () ^ base.GetHashCode ();
      }
      #endregion		
   }

   // An indexer is like a unnamed property that has params
   public class IndexerRepTemplate : PropRepTemplate, IEquatable<IndexerRepTemplate>
   {
      private List<ParamRepTemplate> _params = null;
      [XmlArrayItem("Param")]
      public List<ParamRepTemplate> Params {
         get {
            if (_params == null)
               _params = new List<ParamRepTemplate> ();
            return _params;
         }
      }
		
      private List<ParamRepTemplate> _setParams = null;
      private List<ParamRepTemplate> SetParams {
         get {
            if (_setParams == null)
            {
               _setParams = new List<ParamRepTemplate> ();
               foreach (ParamRepTemplate p in Params)
               {
                  _setParams.Add(p);
               }
               _setParams.Add(new ParamRepTemplate(Type,"value"));
            }
            return _setParams;
         }
      }
		
      [XmlElementAttribute("Get")]
      public override string JavaGet {
         get {
            if (!CanRead) return null;
            if (_javaGet == null) {
               if (_java == null) {
                  return (CanRead ? "${this:16}.get___idx" + mkJavaParams(Params) : null);
               }
               else {
                  return _java;
               }
            }
            else {
               return _javaGet;
            }
         }
         set { _javaGet = value; }
      }
		
      [XmlElementAttribute("Set")]
      public override string JavaSet { 
         get {
            if (_javaSet == null) {
               return (CanWrite ? "${this:16}.set___idx" + mkJavaParams(SetParams): null);
            }
            else {
               return _javaSet;
            }
         }
         set { _javaSet = value; }
      }

      public IndexerRepTemplate()
         : base()
      {
      }

      public IndexerRepTemplate(IndexerRepTemplate copyFrom)
         : base(copyFrom)
      {
         foreach (ParamRepTemplate p in copyFrom.Params)
         {
            Params.Add(new ParamRepTemplate(p));
         }
         foreach (ParamRepTemplate p in copyFrom.SetParams)
         {
            SetParams.Add(new ParamRepTemplate(p));
         }
         if (!String.IsNullOrEmpty(copyFrom.JavaGet))
         {
            JavaGet = copyFrom.JavaGet;
         }
         if (!String.IsNullOrEmpty(copyFrom.JavaSet))
         {
            JavaSet = copyFrom.JavaSet;
         }


      }

      public IndexerRepTemplate(string fType, List<ParamRepTemplate> pars)
         : base(fType, "this")
      {
         _params = pars;
      }

      public IndexerRepTemplate (string fType, List<ParamRepTemplate> pars, string[] imps, string javaGet, string javaSet) : base(fType, "this",imps,javaGet,javaSet)
      {
         _params = pars;
      }


      public override void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         if (Params != null)
         {
            foreach(ParamRepTemplate p in Params)
            {
               p.Apply(args);
            }
         }
         if (_setParams != null)
         {
            foreach(ParamRepTemplate p in _setParams)
            {
               p.Apply(args);
            }
         }
         base.Apply(args);
      }

      #region Equality

      public bool Equals (IndexerRepTemplate other)
      {
         if (other == null)
            return false;
			
         if (Params != other.Params) {
            if (Params == null || other.Params == null || Params.Count != other.Params.Count)
               return false;
            for (int i = 0; i < Params.Count; i++) {
               if (Params[i] != other.Params[i])
                  return false;
            }
         }

         return base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         IndexerRepTemplate temp = obj as IndexerRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (IndexerRepTemplate a1, IndexerRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (IndexerRepTemplate a1, IndexerRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         int hashCode = 0;
         foreach (ParamRepTemplate o in Params) {
            hashCode = hashCode ^ o.GetHashCode() ;
         }
			
         return base.GetHashCode () ^ hashCode;
      }
      #endregion
   }

   // A member of an enum,  may also have a numeric value
   public class EnumMemberRepTemplate : TranslationBase, IEquatable<EnumMemberRepTemplate>
   {

      public string Name { get; set; }
      public string Value { get; set; }


      public EnumMemberRepTemplate() : base()
      {
      }
      public EnumMemberRepTemplate(EnumMemberRepTemplate copyFrom)
         : base(copyFrom)
      {
         if (!String.IsNullOrEmpty(copyFrom.Name))
         {
            Name = copyFrom.Name;
         }

         if (!String.IsNullOrEmpty(copyFrom.Value))
         {
            Value = copyFrom.Value;
         }
      }

      public EnumMemberRepTemplate (string n) : this(n, null, null, null)
      {
      }

      public EnumMemberRepTemplate (string n, string v) : this(n, v, null, null)
      {
      }

      public EnumMemberRepTemplate (string n, string v, string[] imps, string java) : base(imps, java)
      {
         Name = n;
         Value = v;
      }		
		
      public override string mkJava() {
         return "${this:16}." + Name;
      }


      #region Equality
      public bool Equals (EnumMemberRepTemplate other)
      {
         if (other == null)
            return false;
			
         return Name == other.Name && Value == other.Value && base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         EnumMemberRepTemplate temp = obj as EnumMemberRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (EnumMemberRepTemplate a1, EnumMemberRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (EnumMemberRepTemplate a1, EnumMemberRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         return (Name ?? String.Empty).GetHashCode () ^ (Value ?? String.Empty).GetHashCode () ^ base.GetHashCode ();
      }
      #endregion		
		
   }

   // Base Template for classes, interfaces, enums, etc.
   [Serializable]
   public abstract class TypeRepTemplate : TranslationBase, IEquatable<TypeRepTemplate>
   {
      // Type Name
      [XmlElementAttribute("Name")]
      public string TypeName { get; set; }

      private string[] _typeParams = null;
      [XmlArrayItem("Name")]
      public string[] TypeParams { 
         get
         {
            if (_typeParams == null)
            {
               TypeParams = new string[0];
            }
            return _typeParams;
         }
         set
         {
            // First time that TypeParams is set then create InstantiatedTypes as corresponding list of TypeVars 
            if (value != null && InstantiatedTypes == null)
            {
               InstantiatedTypes = new TypeRepTemplate[value.Length];
               for (int i = 0; i < value.Length; i++)
               {
                  InstantiatedTypes[i] = new TypeVarRepTemplate(value[i]);
               }
            }
            _typeParams = value;
         }
      }

      [XmlIgnore]
      public TypeRepTemplate[] InstantiatedTypes { get; set; }

      [XmlIgnore]
      public Dictionary<string,TypeRepTemplate> TyVarMap 
      { get
         { 
            Dictionary<string,TypeRepTemplate> ret = new Dictionary<string,TypeRepTemplate>(TypeParams.Length);
            for (int i = 0; i < TypeParams.Length; i++)
            {
               ret[TypeParams[i]] = InstantiatedTypes[i];
            }
            return ret;
         }
         
      }

      // Path to use when resolving types
      [XmlArrayItem("Use")]
      public string[] Uses { get; set; }

      // Aliases for namespaces
      [XmlArrayItem("Alias")]
      public AliasRepTemplate[] Aliases { get; set; }

      protected List<CastRepTemplate> _casts = null;
      [XmlArrayItem("Cast")]
      public virtual List<CastRepTemplate> Casts {
         get {
            if (_casts == null)
               _casts = new List<CastRepTemplate> ();
            return _casts;
         }
      }

      private string[] _inherits;
      [XmlArrayItem("Type")]
      public string[] Inherits { 
         get { 
            if (_inherits == null)
            {
               _inherits = new string[] { "System.Object" };
            }
            return _inherits; 
         }
         set {
            if (value != null) {
               _inherits= new string[value.Length];
               for (int i = 0; i < value.Length; i++) {
                  _inherits[i] = (value[i] != null ? value[i].Replace("<","*[").Replace(">","]*") : null);
               }
            }
            else {
               _inherits = null;
            }
         }
      }

      // Client can set IsExplicitNull.  If so then null IsA anytype 
      private bool _isExplicitNull = false;
      [XmlIgnore]
      public bool IsExplicitNull
      {
         get
         {
            return _isExplicitNull;
         }
         set
         {
            _isExplicitNull = value;
         }
      }

      // Client can set _isUnboxedType.  If so then we know the expression / type is inboxed 
      private bool _isUnboxedType = false;
      [XmlIgnore]
      public bool IsUnboxedType
      {
         get
         {
            return _isUnboxedType;
         }
         set
         {
            _isUnboxedType = value;
         }
      }

      // Equivalent to "this is TypeVarRepTemplate"
      [XmlIgnore]
      public virtual bool IsTypeVar
      {
         get
         {
            return (this is TypeVarRepTemplate);
         }
      }
      // Equivalent to "this is UnknownRepTemplate"
      [XmlIgnore]
      public virtual bool IsUnknownType
      {
         get
         {
            return (this is UnknownRepTemplate);
         }
      }

      public TypeRepTemplate()
         : base()
      {
         TypeName = null;
         Uses = null;
         Aliases = null;

      }
      protected TypeRepTemplate(string typeName)
         : this()
      {
         TypeName = typeName;
      }

      protected TypeRepTemplate(TypeRepTemplate copyFrom)
         :base(copyFrom)
      {
         if (!String.IsNullOrEmpty(copyFrom.TypeName)) 
         {
            TypeName = copyFrom.TypeName;
         }

         int len = 0;
         if (copyFrom.TypeParams != null)
         {
            len = copyFrom.TypeParams.Length;
            TypeParams = new String[len];
            for (int i = 0; i < len; i++)
            {
               TypeParams[i] = copyFrom.TypeParams[i];
            }
         }

         if (copyFrom.InstantiatedTypes != null)
         {
            len = copyFrom.InstantiatedTypes.Length;
            InstantiatedTypes = new TypeRepTemplate[len];
            for (int i = 0; i < len; i++)
            {
               InstantiatedTypes[i] = copyFrom.InstantiatedTypes[i].Instantiate(null);
            }
         }

         if (copyFrom.Uses != null)
         {
            len = copyFrom.Uses.Length;
            Uses = new String[len];
            for (int i = 0; i < len; i++)
            {
               Uses[i] = copyFrom.Uses[i];
            }
         }

         if (copyFrom.Aliases != null)
         {
            len = copyFrom.Aliases.Length;
            Aliases = new AliasRepTemplate[len];
            for (int i = 0; i < len; i++)
            {
               Aliases[i] = new AliasRepTemplate(copyFrom.Aliases[i]);
            }
         }

         foreach (CastRepTemplate c in copyFrom.Casts)
         {
            Casts.Add(new CastRepTemplate(c));
         }
         
         if (copyFrom.Inherits != null)
         {
            len = copyFrom.Inherits.Length;
            Inherits = new String[len];
            for (int i = 0; i < len; i++)
            {
               Inherits[i] = copyFrom.Inherits[i];
            }
         }

         IsExplicitNull = copyFrom.IsExplicitNull;
         IsUnboxedType = copyFrom.IsUnboxedType;
      }

      protected TypeRepTemplate(string tName, string[] tParams, string[] usePath, AliasRepTemplate[] aliases, string[] imports, string javaTemplate)
         : base(imports, javaTemplate)
      {
         TypeName = tName;
         TypeParams = tParams;
         Uses = usePath;
         Aliases = aliases;
      }
		
      public override string mkJava() {
         if (TypeName == null || TypeName == String.Empty) {
            return null;
         }
         return TypeName.Substring(TypeName.LastIndexOf('.') + 1);
      }

      public override string[] mkImports() {
         if (TypeName !=  null) {
            return new string[] {TypeName};
         }
         else {
            return null;
         }
      }
             
      // IMPORTANT: Call this on the fresh copy because it has the side effect of updating this type's TypeParams.         
      protected Dictionary<string,TypeRepTemplate> mkTypeMap(ICollection<TypeRepTemplate> args) { 
         Dictionary<string,TypeRepTemplate> ret = new Dictionary<string,TypeRepTemplate>();
         if (args != null && args.Count == TypeParams.Length)
         {
            InstantiatedTypes = new TypeRepTemplate[args.Count];
            int i = 0;
            foreach (TypeRepTemplate sub in args)
            {   
               ret[TypeParams[i]] = sub;   
               InstantiatedTypes[i] = sub;   
               i++;
            }
         }
         else
         {
            throw new ArgumentOutOfRangeException("Incorrect number of type arguments supplied when instantiating generic type");
         }
         return ret;
      }
        
      // Make a copy of 'this' and instantiate type variables with types and type variables.
                
      public abstract TypeRepTemplate Instantiate(ICollection<TypeRepTemplate> args);

                
      public override void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         if (Casts != null)
         {
            foreach(CastRepTemplate c in Casts)
            {
               c.Apply(args);
            }
         }
         if (Inherits != null)
         {
            for(int i = 0; i < Inherits.Length; i++)
            {
               Inherits[i] = TemplateUtilities.SubstituteInType(Inherits[i],args);
            }
         }
         base.Apply(args);
      }

      // Resolve a method call (name and arg types)
      public virtual ResolveResult Resolve(String name, List<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv)
      {
         if (Inherits != null)
         {
            foreach (String b in Inherits)
            {
               TypeRepTemplate baseType = BuildType(b, AppEnv);
               if (baseType != null)
               {
                  ResolveResult ret = baseType.Resolve(name,args,AppEnv);
                  if (ret != null)
                     return ret;
               }
            }
         }
         return null;
      }

      // Resolve a field or property access
      public virtual ResolveResult Resolve(String name, bool forWrite, DirectoryHT<TypeRepTemplate> AppEnv)
      {
         if (Inherits != null)
         {
            foreach (String b in Inherits)
            {
               TypeRepTemplate baseType = BuildType(b, AppEnv);
               if (baseType != null)
               {
                  ResolveResult ret = baseType.Resolve(name, forWrite, AppEnv);
                  if (ret != null)
                     return ret;
               }
            }
         }
         return null;
      }

      // Resolve a indexer call (arg types)
      public virtual ResolveResult ResolveIndexer(List<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv)
      {
         if (Inherits != null)
         {
            foreach (String b in Inherits)
            {
               TypeRepTemplate baseType = BuildType(b, AppEnv);
               if (baseType != null)
               {
                  ResolveResult ret = baseType.ResolveIndexer(args,AppEnv);
                  if (ret != null)
                     return ret;
               }
            }
         }
         return null;
      }

      // Resolve a cast from this type to castTo
      public virtual ResolveResult ResolveCastTo(TypeRepTemplate castTo, DirectoryHT<TypeRepTemplate> AppEnv)
      {
         if (Casts != null)
         {
            foreach (CastRepTemplate c in Casts)
            {
               if (c.To != null)
               {
                  // Is this a cast from us?
                  TypeRepTemplate fromTy = null;
                  if (c.From != null)
                  {
                     fromTy = BuildType(c.From, AppEnv);
                  }
                  if (c.From == null || (fromTy != null && fromTy.TypeName == TypeName))
                  {
                     // cast from us
                     TypeRepTemplate toTy = BuildType(c.To, AppEnv);
                     if (toTy.IsA(castTo, AppEnv))
                     {
                        ResolveResult res = new ResolveResult();
                        res.Result = c;
                        res.ResultType = toTy;
                        return res;
                     }
                  }
               }
            }
         }
         if (Inherits != null)
         {
            foreach (String b in Inherits)
            {
               TypeRepTemplate baseType = BuildType(b, AppEnv);
               if (baseType != null)
               {
                  ResolveResult ret = baseType.ResolveCastTo(castTo,AppEnv);
                  if (ret != null)
                     return ret;
               }
            }
         }
         return null;
      }

      // Resolve a cast to this type from castFrom
      public virtual ResolveResult ResolveCastFrom(TypeRepTemplate castFrom, DirectoryHT<TypeRepTemplate> AppEnv)
      {
         if (Casts != null)
         {
            foreach (CastRepTemplate c in Casts)
            {
               if (c.From != null)
               {
                  // Is this a cast to us?
                  TypeRepTemplate toTy = null;
                  if (c.To != null)
                  {
                     toTy = BuildType(c.To, AppEnv);
                  }
                  if (c.To == null || (toTy != null && toTy.TypeName == TypeName))
                  {
                     // cast to us
                     TypeRepTemplate fromTy = BuildType(c.From, AppEnv); 
                     if (castFrom.IsA(fromTy, AppEnv))
                     {
                        ResolveResult res = new ResolveResult();
                        res.Result = c;
                        res.ResultType = toTy;
                        return res;
                     }
                  }
               }
            }
         }
         return null;
      }

      public virtual ResolveResult ResolveIterable(DirectoryHT<TypeRepTemplate> AppEnv)
      {
         if (Inherits != null)
         {
            foreach (String b in Inherits)
            {
               TypeRepTemplate baseType = BuildType(b, AppEnv);
               if (baseType != null)
               {
                  ResolveResult ret = baseType.ResolveIterable(AppEnv);
                  if (ret != null)
                     return ret;
               }
            }
         }
         return null;
      }

      // Returns true if other is a subclass, or implements our interface
      public virtual bool IsA (TypeRepTemplate other, DirectoryHT<TypeRepTemplate> AppEnv) {
         if (this.IsExplicitNull) 
         {
            return true;
         }
         if (other.TypeName == this.TypeName)
         {
            // See if generic arguments 'match'
            if (InstantiatedTypes != null && other.InstantiatedTypes != null && InstantiatedTypes.Length == other.InstantiatedTypes.Length)
            {
               bool isA = true;
               for (int i = 0; i < InstantiatedTypes.Length; i++)
               {
                  if (!InstantiatedTypes[i].IsA(other.InstantiatedTypes[i],AppEnv))
                  {
                     isA = false;
                     break;
                  }
               }
               return isA;
            }
            else
            {
               return InstantiatedTypes == other.InstantiatedTypes;
            }
         }
         else if (Inherits != null)
         {
            foreach (String ibase in Inherits)
            {
               TypeRepTemplate tbase = BuildType(ibase, AppEnv, new UnknownRepTemplate(ibase));
               if (tbase.IsA(other,AppEnv))
               {
                  return true;
               }
            }
         }
         return false;
      }
		
      // Builds a type rep from a string representation
      // "type_name"
      // "<type>[]"
      // "<type>[<type>, ...]"
      public TypeRepTemplate BuildType(string typeRep, DirectoryHT<TypeRepTemplate> AppEnv)
      {
         return BuildType(typeRep, AppEnv, null);
      }

      public TypeRepTemplate BuildType(string typeRep, DirectoryHT<TypeRepTemplate> AppEnv, TypeRepTemplate def)
      {
         if (String.IsNullOrEmpty(typeRep))
            return def;

         if (typeRep.EndsWith("[]"))
         {
            //Array
            string baseType = typeRep.Substring(0, typeRep.Length - 2);
            TypeRepTemplate baseTypeRep = BuildType(baseType, AppEnv);
            if (baseTypeRep == null)
            {
               return def;
            }
            else
            {
               TypeRepTemplate arrayType = AppEnv.Search("System.Array'1");
               return arrayType.Instantiate(new TypeRepTemplate[] { baseTypeRep });
            }
         }
         else
         {
            // todo: search for type[type, ...]
            return AppEnv.Search(Uses, typeRep, def);
         }
      }

      #region deserialization
		
      private static object Deserialize (Stream fs, System.Type t)
      {
         object o = null;
			
         XmlSerializer serializer = new XmlSerializer (t, Constants.TranslationTemplateNamespace);
         o = serializer.Deserialize (fs);
         return o;
      }


      private static TypeRepTemplate Deserialize (Stream s)
      {
         TypeRepTemplate ret = null;
			
         XmlReaderSettings settings = new XmlReaderSettings ();
         settings.IgnoreWhitespace = true;
         settings.IgnoreComments = true;
         XmlReader reader = XmlReader.Create (s, settings);
			
         //XmlTextReader reader = new XmlTextReader(s);
         string typeType = null;
         // class, interface, enum, etc.
         bool found = false;
			
         try {
            while (reader.Read () && !found) {
               if (reader.NodeType == XmlNodeType.Element) {
                  switch (reader.LocalName) {
                     case "Class":
                        typeType = "Twiglet.CS2J.Translator.TypeRep.ClassRepTemplate";
                        break;
                     case "Struct":
                        typeType = "Twiglet.CS2J.Translator.TypeRep.StructRepTemplate";
                        break;
                     case "Interface":
                        typeType = "Twiglet.CS2J.Translator.TypeRep.InterfaceRepTemplate";
                        break;
                     case "Enum":
                        typeType = "Twiglet.CS2J.Translator.TypeRep.EnumRepTemplate";
                        break;
                     case "Delegate":
                        typeType = "Twiglet.CS2J.Translator.TypeRep.DelegateRepTemplate";
                        break;
                     default:
                        typeType = "UnknownType";
                        break;
                  }
                  found = true;
               }
            }
            s.Seek (0, SeekOrigin.Begin);
            ret = (TypeRepTemplate)Deserialize (s, System.Type.GetType (typeType));
         } catch (Exception e) {
            Console.WriteLine ("WARNING -- (Deserialize) " + e.Message);
         }
			
         return ret;
      }


      public static TypeRepTemplate newInstance (Stream s)
      {
         return (TypeRepTemplate)Deserialize (s);
      }
		
      #endregion deserialization
		
      #region Equality
      public bool Equals (TypeRepTemplate other)
      {
         if (other == null)
            return false;
			
         if (Uses != other.Uses) {
            if (Uses == null || other.Uses == null || Uses.Length != other.Uses.Length)
               return false;
            for (int i = 0; i < Uses.Length; i++) {
               if (Uses[i] != other.Uses[i])
                  return false;
            }
         }
         if (Aliases != other.Aliases) {
            if (Aliases == null || other.Aliases == null || Aliases.Length != other.Aliases.Length)
               return false;
            for (int i = 0; i < Aliases.Length; i++) {
               if (Aliases[i] != other.Aliases[i])
                  return false;
            }
         }
         if (TypeParams != other.TypeParams) {
            if (TypeParams == null || other.TypeParams == null || TypeParams.Length != other.TypeParams.Length)
               return false;
            for (int i = 0; i < TypeParams.Length; i++) {
               if (TypeParams[i] != other.TypeParams[i])
                  return false;
            }
         }
			
         if (Casts != other.Casts) {
            if (Casts == null || other.Casts == null || Casts.Count != other.Casts.Count)
               return false;
            for (int i = 0; i < Casts.Count; i++) {
               if (Casts[i] != other.Casts[i])
                  return false;
            }
         }
         if (InstantiatedTypes != other.InstantiatedTypes)
         {
            if (InstantiatedTypes == null || other.InstantiatedTypes == null || InstantiatedTypes.Length != other.InstantiatedTypes.Length)
               return false;
            for (int i = 0; i < InstantiatedTypes.Length; i++)
            {
               if (InstantiatedTypes[i] != other.InstantiatedTypes[i])
                  return false;
            }
         }

         return IsExplicitNull == other.IsExplicitNull && IsUnboxedType == other.IsUnboxedType && TypeName == other.TypeName && base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         TypeRepTemplate temp = obj as TypeRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (TypeRepTemplate a1, TypeRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (TypeRepTemplate a1, TypeRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         int hashCode = base.GetHashCode ();
         if (Uses != null) {
            foreach (string e in Uses) {
               hashCode ^= e.GetHashCode();
            }
         }
         if (Aliases != null) {
            foreach (AliasRepTemplate e in Aliases) {
               hashCode ^= e.GetHashCode();
            }
         }
         if (TypeParams != null) {
            foreach (string e in TypeParams) {
               hashCode ^= e.GetHashCode();
            }
         }
         if (Casts != null) {
            foreach (CastRepTemplate e in Casts) {
               hashCode ^= e.GetHashCode();
            }
         }
         if (InstantiatedTypes != null)
         {
            foreach (TypeRepTemplate ty in InstantiatedTypes)
            {
               hashCode ^= ty.GetHashCode();
            }
         }

         return (Java ?? String.Empty).GetHashCode() ^ IsExplicitNull.GetHashCode() ^ IsUnboxedType.GetHashCode() ^ hashCode;
      }
      #endregion		
		
      private string _formattedTypeName = null;
      protected string mkFormattedTypeName(bool incNameSpace)
      {
         if (_formattedTypeName == null)
         {
                            
            StringBuilder fmt = new StringBuilder();
            if (TypeName == "System.Array")
            {
               fmt.Append(InstantiatedTypes[0].mkFormattedTypeName(incNameSpace));
               fmt.Append("[]");
            }
            else
            {
               fmt.Append(TypeName.Substring(incNameSpace ? 0 : TypeName.LastIndexOf('.')+1));
               if (InstantiatedTypes != null && InstantiatedTypes.Length > 0)
               {
                  bool isFirst = true;
                  fmt.Append("<");
                  foreach (TypeRepTemplate t in InstantiatedTypes)
                  {
                     if (!isFirst)
                        fmt.Append(", ");
                     fmt.Append(t.mkFormattedTypeName(incNameSpace));
                     isFirst = false;
                  }
                  fmt.Append(">");
               }
            }
            _formattedTypeName = fmt.ToString();
         }
         return _formattedTypeName;
      }

      protected string mkFormattedTypeName()
      {
         return mkFormattedTypeName(true);
      }

      public override String ToString()
      {
         return mkFormattedTypeName();
      }
   }

   [XmlType("Enum")]
   public class EnumRepTemplate : TypeRepTemplate, IEquatable<EnumRepTemplate>
   {
      private List<EnumMemberRepTemplate> _members = null;
      [XmlArrayItem("Member")]
      public List<EnumMemberRepTemplate> Members {
         get {
            if (_members == null)
               _members = new List<EnumMemberRepTemplate> ();
            return _members;
         }
      }

      private List<CastRepTemplate> _enumCasts = null;
      private List<CastRepTemplate> EnumCasts {
         get {
            if (_enumCasts == null)
            {
               _enumCasts = new List<CastRepTemplate> ();
               CastRepTemplate kast = new CastRepTemplate();
               kast.From = "System.Int32";
               kast.Java = "${TYPEOF_totype:16}.values()[${expr}]";
               _enumCasts.Add(kast);
               kast = new CastRepTemplate();
               kast.To = "System.Int32";
               kast.Java = "((Enum)${expr}).ordinal()";
               _enumCasts.Add(kast);
            }
            return _enumCasts;
         }
      }

      public override List<CastRepTemplate> Casts {
         get {
            if (_casts == null)
            {
               return EnumCasts;
            }
            else
            {
               return _casts;        
            }
         }
      }

      public EnumRepTemplate()
         : base()
      {
         Inherits = new string[] { "System.Enum" };
      }

      public EnumRepTemplate(EnumRepTemplate copyFrom)
         : base(copyFrom)
      {
         foreach (EnumMemberRepTemplate m in copyFrom.Members)
         {
            Members.Add(new EnumMemberRepTemplate(m));
         }
      }

      public EnumRepTemplate (List<EnumMemberRepTemplate> ms) : base()
      {
         _members = ms;
      }

      public override ResolveResult Resolve(String name, bool forWrite, DirectoryHT<TypeRepTemplate> AppEnv)
      {
         if (Members != null)
         {
            foreach (EnumMemberRepTemplate m in Members)
            {
               if (m.Name == name)
               {
                  ResolveResult res = new ResolveResult();
                  res.Result = m;
                  res.ResultType = this;
                  return res;
               }
            }
         }
         return base.Resolve(name, forWrite, AppEnv);
      }
      public override TypeRepTemplate Instantiate(ICollection<TypeRepTemplate> args)
      {
         EnumRepTemplate copy = new EnumRepTemplate(this);
         copy.Apply(mkTypeMap(args));
         return copy;
      }
      #region Equality
      public bool Equals (EnumRepTemplate other)
      {
         if (other == null)
            return false;
			
         if (Members != other.Members) {
            if (Members == null || other.Members == null || Members.Count != other.Members.Count)
               return false;
            for (int i = 0; i < Members.Count; i++) {
               if (Members[i] != other.Members[i])
                  return false;
            }
         }
			
         return base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         EnumRepTemplate temp = obj as EnumRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (EnumRepTemplate a1, EnumRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (EnumRepTemplate a1, EnumRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         int hashCode = base.GetHashCode ();
         if (Members != null) {
            foreach (EnumMemberRepTemplate e in Members) {
               hashCode ^= e.GetHashCode();
            }
         }
         return hashCode;
      }
      #endregion		
   }

   [XmlType("Delegate")]
   public class DelegateRepTemplate : TypeRepTemplate, IEquatable<DelegateRepTemplate>
   {
      private List<ParamRepTemplate> _params = null;
      [XmlArrayItem("Param")]
      public List<ParamRepTemplate> Params {
         get {
            if (_params == null)
               _params = new List<ParamRepTemplate> ();
            return _params;
         }
         set {
            _params = value;
         }
      }

      private string _return;
      public string Return { 
         get { return _return; }
         set {
            _return=value.Replace("<","*[").Replace(">","]*");
         }
      }

      public DelegateRepTemplate()
         : base()
      {
      }

      public DelegateRepTemplate(DelegateRepTemplate copyFrom)
         : base(copyFrom)
      {
         foreach (ParamRepTemplate p in copyFrom.Params)
         {
            Params.Add(new ParamRepTemplate(p));
         }

         if (!String.IsNullOrEmpty(copyFrom.Return))
         {
            Return = copyFrom.Return;
         }
      }

      public DelegateRepTemplate(string retType, List<ParamRepTemplate> args)
         : base()
      {
         Return = retType;
         _params = args;
      }

      public override string mkJava() {
         return "${delegate:16}.Invoke" + mkJavaParams(Params);
      }

      public override void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         if (Params != null)
         {
            foreach(ParamRepTemplate p in Params)
            {
               p.Apply(args);
            }
         }
         if (Return != null)
         {
            Return = TemplateUtilities.SubstituteInType(Return, args);
         }
         base.Apply(args);
      }
      public override TypeRepTemplate Instantiate(ICollection<TypeRepTemplate> args)
      {
         DelegateRepTemplate copy = new DelegateRepTemplate(this);
         copy.Apply(mkTypeMap(args));
         return copy;
      }

      #region Equality
      public bool Equals (DelegateRepTemplate other)
      {
         if (other == null)
            return false;
			
         if (Params != other.Params) {
            if (Params == null || other.Params == null || Params.Count != other.Params.Count)
               return false;
            for (int i = 0; i < Params.Count; i++) {
               if (Params[i] != other.Params[i])
                  return false;
            }
         }
			
         return Return == other.Return && base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         DelegateRepTemplate temp = obj as DelegateRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (DelegateRepTemplate a1, DelegateRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (DelegateRepTemplate a1, DelegateRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         int hashCode = base.GetHashCode ();
         if (Params != null) {
            foreach (ParamRepTemplate e in Params) {
               hashCode ^= e.GetHashCode();
            }
         }
         return (Return ?? String.Empty).GetHashCode() ^ hashCode;
      }
      #endregion	
   }

   // Base Template for classes, interfaces, etc.
   [XmlType("Interface")]
   public class InterfaceRepTemplate : TypeRepTemplate, IEquatable<InterfaceRepTemplate>
   {
      private List<MethodRepTemplate> _methods = null;
      [XmlArrayItem("Method")]
      public List<MethodRepTemplate> Methods {
         get {
            if (_methods == null)
               _methods = new List<MethodRepTemplate> ();
            return _methods;
         }
      }
		
      private List<PropRepTemplate> _properties = null;
      [XmlArrayItem("Property")]
      public List<PropRepTemplate> Properties {
         get {
            if (_properties == null)
               _properties = new List<PropRepTemplate> ();
            return _properties;
         }
      }
		
      private List<FieldRepTemplate> _events = null;
      [XmlArrayItem("Event")]
      public List<FieldRepTemplate> Events {
         get {
            if (_events == null)
               _events = new List<FieldRepTemplate> ();
            return _events;
         }
      }
		
      private List<IndexerRepTemplate> _indexers = null;
      [XmlArrayItem("Indexer")]
         public List<IndexerRepTemplate> Indexers {
         get {
            if (_indexers == null)
               _indexers = new List<IndexerRepTemplate> ();
            return _indexers;
         }
      }
		
      private IterableRepTemplate _iterable = null;
      public IterableRepTemplate Iterable {
         get {
            return _iterable;
         }
         set {
            _iterable = value;
         }
      }
		
      public InterfaceRepTemplate () : base()
      {
         Inherits = null;
      }

      public InterfaceRepTemplate(InterfaceRepTemplate copyFrom)
         : base(copyFrom)
      {
         foreach (MethodRepTemplate m in copyFrom.Methods)
         {
            Methods.Add(new MethodRepTemplate(m));
         }

         foreach (PropRepTemplate p in copyFrom.Properties)
         {
            Properties.Add(new PropRepTemplate(p));
         }

         foreach (FieldRepTemplate e in copyFrom.Events)
         {
            Events.Add(new FieldRepTemplate(e));
         }

         foreach (IndexerRepTemplate i in copyFrom.Indexers)
         {
            Indexers.Add(new IndexerRepTemplate(i));
         }

         if (copyFrom.Iterable != null)
         {
            Iterable = new IterableRepTemplate(copyFrom.Iterable);
         }
      }

      public InterfaceRepTemplate(string typeName)
         : base(typeName)
      {
      }

      protected InterfaceRepTemplate(string tName, string[] tParams, string[] usePath, AliasRepTemplate[] aliases, string[] inherits, List<MethodRepTemplate> ms, List<PropRepTemplate> ps, List<FieldRepTemplate> es, List<IndexerRepTemplate> ixs, string[] imps, string javaTemplate) 
         : base(tName, tParams, usePath, aliases, imps, javaTemplate)
      {
         Inherits = inherits;
         _methods = ms;
         _properties = ps;
         _events = es;
         _indexers = ixs;
      }

		
      public override void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         if (Methods != null)
         {
            foreach(MethodRepTemplate m in Methods)
            {
               m.Apply(args);
            }
         }
         if (Properties != null)
         {
            foreach(PropRepTemplate p in Properties)
            {
               p.Apply(args);
            }
         }
         if (Events != null)
         {
            foreach(FieldRepTemplate e in Events)
            {
               e.Apply(args);
            }
         }
         if (Indexers != null)
         {
             foreach (IndexerRepTemplate i in Indexers)
             {
                 i.Apply(args);
             }
         }
         if (Iterable != null)
         {
             Iterable.Apply(args);
         }
         base.Apply(args);
      }

      // Returns true if we are a subclass of other, or implements its interface
      public override bool IsA (TypeRepTemplate other,  DirectoryHT<TypeRepTemplate> AppEnv) {
         InterfaceRepTemplate i = other as InterfaceRepTemplate;
         if (i == null)
         {
            return false;                         
         }
         if (i.TypeName == this.TypeName)
         {
            return true;
         }
         return base.IsA(other,AppEnv);
      }

      public override ResolveResult Resolve(String name, bool forWrite, DirectoryHT<TypeRepTemplate> AppEnv)
      {
        
         if (Properties != null)
         {
            foreach (PropRepTemplate p in Properties)
            {
               if (p.Name == name && ((forWrite && p.CanWrite) || (!forWrite && p.CanRead)))
               {
                  ResolveResult res = new ResolveResult();
                  res.Result = p;
                  res.ResultType = BuildType(p.Type, AppEnv);
                  return res;
               }
            }
         }
         return base.Resolve(name, forWrite, AppEnv);
      }

      public override ResolveResult Resolve(String name, List<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv)
      {
        
         if (Methods != null)
         {
            foreach (MethodRepTemplate m in Methods)
            {
               if (m.Name == name)
               {
                  bool matchingArgs = true;
                  // If either params are null then make sure both represent zero length args
                  if (m.Params == null || args == null)
                  {
                     // Are they both zero length?
                     matchingArgs = (m.Params == null || m.Params.Count == 0) && (args == null || args.Count == 0);
                  }
                  else
                  {
                     // Are num args the same?
                     if (m.Params.Count != args.Count)
                     {
                        matchingArgs = false;
                     }
                     else
                     {
                        // check that for each argument in the caller its type 'IsA' the type of the formal argument
                        for (int idx = 0; idx < m.Params.Count; idx++) {
                           if (args[idx] == null || !args[idx].IsA(BuildType(m.Params[idx].Type, AppEnv, new UnknownRepTemplate(m.Params[idx].Type)),AppEnv))
                           {
                              matchingArgs = false;
                              break;
                           }
                        }
                     }
                  }
                  if (matchingArgs)
                  {
                     ResolveResult res = new ResolveResult();
                     res.Result = m;
                     res.ResultType = BuildType(m.Return, AppEnv);
                     return res;
                  }
               }
            }
         }
         return base.Resolve(name, args, AppEnv);
      }

      public override ResolveResult ResolveIndexer(List<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv)
      {
        
         if (Indexers != null)
         {
            foreach (IndexerRepTemplate i in Indexers)
            {
               bool matchingArgs = true;
               // If either params are null then make sure both represent zero length args
               if (i.Params == null || args == null)
               {
                  // Are they both zero length?
                  matchingArgs = (i.Params == null || i.Params.Count == 0) && (args == null || args.Count == 0);
               }
               else
               {
                  // Are num args the same?
                  if (i.Params.Count != args.Count)
                  {
                     matchingArgs = false;
                  }
                  else
                  {
                     // check that for each argument in the caller its type 'IsA' the type of the formal argument
                     for (int idx = 0; idx < i.Params.Count; idx++) {
                        if (args[idx] == null || !args[idx].IsA(BuildType(i.Params[idx].Type, AppEnv, new UnknownRepTemplate(i.Params[idx].Type)),AppEnv))
                        {
                           matchingArgs = false;
                           break;
                        }
                     }
                  }
                  if (matchingArgs)
                  {
                     ResolveResult res = new ResolveResult();
                     res.Result = i;
                     res.ResultType = BuildType(i.Type, AppEnv);
                     return res;
                  }
               }
            }
         }
         return base.ResolveIndexer(args, AppEnv);
      }

      public override ResolveResult ResolveIterable(DirectoryHT<TypeRepTemplate> AppEnv)
      {
        
         if (Iterable != null)
         {
            ResolveResult res = new ResolveResult();
            res.Result = Iterable;
            res.ResultType = BuildType(Iterable.ElementType, AppEnv);
            return res;
         }
         return base.ResolveIterable(AppEnv);
      }
      public override TypeRepTemplate Instantiate(ICollection<TypeRepTemplate> args)
      {
         InterfaceRepTemplate copy = new InterfaceRepTemplate(this);
         copy.Apply(mkTypeMap(args));
         return copy;
      }

      #region Equality
      public bool Equals (InterfaceRepTemplate other)
      {
         if (other == null)
            return false;
			
         if (Inherits != other.Inherits) {
            if (Inherits == null || other.Inherits == null || Inherits.Length != other.Inherits.Length)
               return false;
            for (int i = 0; i < Inherits.Length; i++) {
               if (Inherits[i] != other.Inherits[i])
                  return false;
            }
         }
			
         if (Methods != other.Methods) {
            if (Methods == null || other.Methods == null || Methods.Count != other.Methods.Count)
               return false;
            for (int i = 0; i < Methods.Count; i++) {
               if (Methods[i] != other.Methods[i])
                  return false;
            }
         }

         if (Properties != other.Properties) {
            if (Properties == null || other.Properties == null || Properties.Count != other.Properties.Count)
               return false;
            for (int i = 0; i < Properties.Count; i++) {
               if (Properties[i] != other.Properties[i])
                  return false;
            }
         }

         if (Events != other.Events) {
            if (Events == null || other.Events == null || Events.Count != other.Events.Count)
               return false;
            for (int i = 0; i < Events.Count; i++) {
               if (Events[i] != other.Events[i])
                  return false;
            }
         }

         if (Indexers != other.Indexers) {
            if (Indexers == null || other.Indexers == null || Indexers.Count != other.Indexers.Count)
               return false;
            for (int i = 0; i < Indexers.Count; i++) {
               if (Indexers[i] != other.Indexers[i])
                  return false;
            }
         }
			
         return base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         InterfaceRepTemplate temp = obj as InterfaceRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (InterfaceRepTemplate a1, InterfaceRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (InterfaceRepTemplate a1, InterfaceRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         int hashCode = base.GetHashCode ();
         if (Inherits != null) {
            foreach (string e in Inherits) {
               hashCode ^= e.GetHashCode();
            }
         }
         if (Methods != null) {
            foreach (MethodRepTemplate e in Methods) {
               hashCode ^= e.GetHashCode();
            }
         }
         if (Properties != null) {
            foreach (PropRepTemplate e in Properties) {
               hashCode ^= e.GetHashCode();
            }
         }
         if (Events != null) {
            foreach (FieldRepTemplate e in Events) {
               hashCode ^= e.GetHashCode();
            }
         }
         if (Indexers != null) {
            foreach (IndexerRepTemplate e in Indexers) {
               hashCode ^= e.GetHashCode();
            }
         }
         return hashCode;
      }
      #endregion	
   }

   [XmlType("Class")]
   public class ClassRepTemplate : InterfaceRepTemplate, IEquatable<ClassRepTemplate>
   {

      private List<ConstructorRepTemplate> _constructors = null;
      [XmlArrayItem("Constructor")]
         public List<ConstructorRepTemplate> Constructors {
         get {
            if (_constructors == null)
               _constructors = new List<ConstructorRepTemplate> ();
            return _constructors;
         }
      }

      private List<FieldRepTemplate> _fields = null;
      [XmlArrayItem("Field")]
         public List<FieldRepTemplate> Fields {
         get {
            if (_fields == null)
               _fields = new List<FieldRepTemplate> ();
            return _fields;
         }
      }

      private List<MethodRepTemplate> _unaryOps = null;
      [XmlArrayItem("UnaryOp")]
         public List<MethodRepTemplate> UnaryOps {
         get {
            if (_unaryOps == null)
               _unaryOps = new List<MethodRepTemplate> ();
            return _unaryOps;
         }
      }

      private List<MethodRepTemplate> _binaryOps = null;
      [XmlArrayItem("BinaryOp")]
         public List<MethodRepTemplate> BinaryOps {
         get {
            if (_binaryOps == null)
               _binaryOps = new List<MethodRepTemplate> ();
            return _binaryOps;
         }
      }

      public ClassRepTemplate ()
      {
      }

      public ClassRepTemplate(ClassRepTemplate copyFrom)
         : base(copyFrom)
      {
         foreach (ConstructorRepTemplate c in copyFrom.Constructors)
         {
            Constructors.Add(new ConstructorRepTemplate(c));
         }

         foreach (FieldRepTemplate f in copyFrom.Fields)
         {
            Fields.Add(new FieldRepTemplate(f));
         }

         foreach (MethodRepTemplate u in copyFrom.UnaryOps)
         {
            UnaryOps.Add(new MethodRepTemplate(u));
         }

         foreach (MethodRepTemplate b in copyFrom.BinaryOps)
         {
            BinaryOps.Add(new MethodRepTemplate(b));
         }

      }

      public ClassRepTemplate(string typeName)
         : base(typeName)
      {
      }

      public ClassRepTemplate(string tName, string[] tParams, string[] usePath, AliasRepTemplate[] aliases, string[] inherits, List<ConstructorRepTemplate> cs, List<MethodRepTemplate> ms, List<PropRepTemplate> ps, List<FieldRepTemplate> fs, List<FieldRepTemplate> es, List<IndexerRepTemplate> ixs, List<CastRepTemplate> cts,
                              string[] imports, string javaTemplate) 
         : base(tName, tParams, usePath, aliases, inherits, ms, ps, es, ixs, imports, javaTemplate)
      {
         _constructors = cs;
         _fields = fs;
         _casts = cts;
      }

      public ClassRepTemplate (string tName, string[] tParams, string[] usePath, AliasRepTemplate[] aliases, string[] inherits, List<ConstructorRepTemplate> cs, List<MethodRepTemplate> ms, List<PropRepTemplate> ps, List<FieldRepTemplate> fs, List<FieldRepTemplate> es, List<IndexerRepTemplate> ixs, List<CastRepTemplate> cts)
         : base(tName, tParams, usePath, aliases, inherits, ms, ps, es, ixs, null, null)
      {
         _constructors = cs;
         _fields = fs;
         _casts = cts;
      }

      public override void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         if (Constructors != null)
         {
            foreach(ConstructorRepTemplate c in Constructors)
            {
               c.Apply(args);
            }
         }
         if (Fields != null)
         {
            foreach(FieldRepTemplate f in Fields)
            {
               f.Apply(args);
            }
         }

         if (UnaryOps != null)
         {
            foreach(MethodRepTemplate u in UnaryOps)
            {
               u.Apply(args);
            }
         }

         if (BinaryOps != null)
         {
            foreach(MethodRepTemplate b in BinaryOps)
            {
               b.Apply(args);
            }
         }
         base.Apply(args);
      }


      public override ResolveResult Resolve(String name, bool forWrite, DirectoryHT<TypeRepTemplate> AppEnv)
      {
        
         if (Fields != null)
         {
            foreach (FieldRepTemplate f in Fields)
            {
               if (f.Name == name)
               {
                  ResolveResult res = new ResolveResult();
                  res.Result = f;
                  res.ResultType = BuildType(f.Type, AppEnv);
                  return res;
               }
            }
         }
         return base.Resolve(name, forWrite, AppEnv);
      }

      public ResolveResult Resolve(List<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv)
      {
        
         if (Constructors != null)
         {
            foreach (ConstructorRepTemplate c in Constructors)
            {
               bool matchingArgs = true;
               // If either params are null then make sure both represent zero length args
               if (c.Params == null || args == null)
               {
                  // Are they both zero length?
                  matchingArgs = (c.Params == null || c.Params.Count == 0) && (args == null || args.Count == 0);
               }
               else
               {
                  // Are num args the same?
                  if (c.Params.Count != args.Count)
                  {
                     matchingArgs = false;
                  }
                  else
                  {
                     // check that for each argument in the caller its type 'IsA' the type of the formal argument
                     for (int idx = 0; idx < c.Params.Count; idx++) {
                        if (args[idx] == null || !args[idx].IsA(BuildType(c.Params[idx].Type, AppEnv, new UnknownRepTemplate(c.Params[idx].Type)),AppEnv))
                        {
                           matchingArgs = false;
                           break;
                        }
                     }
                  }
               }
               if (matchingArgs)
               {
                  ResolveResult res = new ResolveResult();
                  res.Result = c;
                  res.ResultType = this;
                  return res;
               }
            }
         }
         // We don't search base,  constructors aren't inherited
         return null;
      }
      public override TypeRepTemplate Instantiate(ICollection<TypeRepTemplate> args)
      {
         ClassRepTemplate copy = new ClassRepTemplate(this);
         copy.Apply(copy.mkTypeMap(args));
         return copy;
      }

      #region Equality
      public bool Equals (ClassRepTemplate other)
      {
         if (other == null)
            return false;
			
         if (Constructors != other.Constructors) {
            if (Constructors == null || other.Constructors == null || Constructors.Count != other.Constructors.Count)
               return false;
            for (int i = 0; i < Constructors.Count; i++) {
               if (Constructors[i] != other.Constructors[i])
                  return false;
            }
         }

         if (Fields != other.Fields) {
            if (Fields == null || other.Fields == null || Fields.Count != other.Fields.Count)
               return false;
            for (int i = 0; i < Fields.Count; i++) {
               if (Fields[i] != other.Fields[i])
                  return false;
            }
         }

         if (UnaryOps != other.UnaryOps) {
            if (UnaryOps == null || other.UnaryOps == null || UnaryOps.Count != other.UnaryOps.Count)
               return false;
            for (int i = 0; i < UnaryOps.Count; i++) {
               if (UnaryOps[i] != other.UnaryOps[i])
                  return false;
            }
         }

         if (BinaryOps != other.BinaryOps) {
            if (BinaryOps == null || other.BinaryOps == null || BinaryOps.Count != other.BinaryOps.Count)
               return false;
            for (int i = 0; i < BinaryOps.Count; i++) {
               if (BinaryOps[i] != other.BinaryOps[i])
                  return false;
            }
         }


         return base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         ClassRepTemplate temp = obj as ClassRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (ClassRepTemplate a1, ClassRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (ClassRepTemplate a1, ClassRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         int hashCode = base.GetHashCode ();
         if (Constructors != null) {
            foreach (ConstructorRepTemplate e in Constructors) {
               hashCode ^= e.GetHashCode();
            }
         }
         if (Fields != null) {
            foreach (FieldRepTemplate e in Fields) {
               hashCode ^= e.GetHashCode();
            }
         }

         return hashCode;
      }
      #endregion	
         
   }

   [XmlType("Struct")]
   public class StructRepTemplate : ClassRepTemplate, IEquatable<StructRepTemplate>
   {

      public StructRepTemplate ()
      {
      }

      public StructRepTemplate(StructRepTemplate copyFrom)
         : base(copyFrom)
      {
      }
        
      public StructRepTemplate(string typeName)
         : base(typeName)
      {
      }

      public StructRepTemplate (string tName, string[] tParams, string[] usePath, AliasRepTemplate[] aliases, string[] inherits, List<ConstructorRepTemplate> cs, List<MethodRepTemplate> ms, List<PropRepTemplate> ps, List<FieldRepTemplate> fs, List<FieldRepTemplate> es, List<IndexerRepTemplate> ixs, List<CastRepTemplate> cts,
                                string[] imports, string javaTemplate) : base(tName, tParams, usePath, aliases, inherits, cs, ms, ps, fs, es, ixs, cts,
                                                                              imports, javaTemplate)
      {
      }

      public StructRepTemplate (string tName, string[] tParams, string[] usePath, AliasRepTemplate[] aliases, string[] inherits, List<ConstructorRepTemplate> cs, List<MethodRepTemplate> ms, List<PropRepTemplate> ps, List<FieldRepTemplate> fs, List<FieldRepTemplate> es, List<IndexerRepTemplate> ixs, List<CastRepTemplate> cts)
         : base(tName, tParams, usePath, aliases, inherits, cs, ms, ps, fs, es, ixs, cts,	null, null)
      {
      }
		
      public override ResolveResult Resolve(String name, bool forWrite, DirectoryHT<TypeRepTemplate> AppEnv)
      {
         return base.Resolve(name, forWrite, AppEnv);
      }

      #region Equality
      public bool Equals (StructRepTemplate other)
      {
         return base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         StructRepTemplate temp = obj as StructRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (StructRepTemplate a1, StructRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (StructRepTemplate a1, StructRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         return base.GetHashCode ();
      }
      #endregion
   }
	
   [XmlType("UnknownType")]
   // For now, making as compatible as we can so inheriting from struct
   public class UnknownRepTemplate : StructRepTemplate, IEquatable<UnknownRepTemplate>
   {

      public UnknownRepTemplate ()
      {
      }

      public UnknownRepTemplate (string typeName) : base(typeName)
      {
         Inherits = new String[] { "System.Object" };
      }

      public UnknownRepTemplate (UnknownRepTemplate copyFrom) : base(copyFrom)
      {
      }

      public override string[] Imports { 
         get {
            return new string[0];
         }
      }

      public override string mkJava() {
         return TypeName;
      }

      public override TypeRepTemplate Instantiate(ICollection<TypeRepTemplate> args)
      {
         UnknownRepTemplate copy = new UnknownRepTemplate(this);
         // don't instantiate, its an unknown type: copy.Apply(mkTypeMap(args));
         return copy;
      }
		
      #region Equality
      public bool Equals (UnknownRepTemplate other)
      {
         return base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         UnknownRepTemplate temp = obj as UnknownRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (UnknownRepTemplate a1, UnknownRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (UnknownRepTemplate a1, UnknownRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         return base.GetHashCode ();
      }
      #endregion
		
		
         }

   [XmlType("TypeVariable")]
   // Represents Type Variables.  We inherit from ClassRepTemplate to that
   // Type Variables have the same interface as types, but we can override as
   // neccessary
   public class TypeVarRepTemplate : ClassRepTemplate, IEquatable<TypeVarRepTemplate>
   {

      public TypeVarRepTemplate ()
      {
      }

      public TypeVarRepTemplate (string typeName) : base(typeName)
      {
      }

      public TypeVarRepTemplate (TypeVarRepTemplate copyFrom) : base(copyFrom)
      {
      }

      public override string[] Imports { 
         get {
            return new string[0];
         }
      }

      public override TypeRepTemplate Instantiate(ICollection<TypeRepTemplate> args)
      {
         TypeVarRepTemplate copy = new TypeVarRepTemplate(this);
         if (args != null && args.Count > 0)
         {
            copy.TypeName = args.GetEnumerator().Current.TypeName;
         }
         return copy;
      }
		
      public override bool IsA (TypeRepTemplate other,  DirectoryHT<TypeRepTemplate> AppEnv) {
         return false;                         
      }

      #region Equality
      public bool Equals (TypeVarRepTemplate other)
      {
         return base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         TypeVarRepTemplate temp = obj as TypeVarRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (TypeVarRepTemplate a1, TypeVarRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (TypeVarRepTemplate a1, TypeVarRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         return base.GetHashCode ();
      }
      #endregion
		
		
   }

    
   public class ResolveResult
   {
      public TranslationBase Result
      {
         get; set;
      }
      public TypeRepTemplate ResultType
      {
         get; set;
      }

   }



}
