/*
   Copyright 2010-2013 Kevin Glynn (kevin.glynn@twigletsoftware.com)
   Copyright 2007-2013 Rustici Software, LLC

This program is free software: you can redistribute it and/or modify
it under the terms of the MIT/X Window System License

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You should have received a copy of the MIT/X Window System License
along with this program.  If not, see 

   <http://www.opensource.org/licenses/mit-license>
*/

using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using System.IO;
using System.Xml;
using System.Xml.Schema;
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
       public static readonly bool DO_IMPLICIT_CASTS=false;
      public static string Substitute(string c, Dictionary<string,TypeRepTemplate> argMap)
      {
         String ret = c;
         if (argMap.ContainsKey(c))
         {
            ret = argMap[c].TypeName;
         }
         return ret;
      }

      private class TypeVarMapper
      {
         private Dictionary<string,TypeRepTemplate> myArgMap;

         public TypeVarMapper(Dictionary<string,TypeRepTemplate> inArgMap)
         {
            myArgMap = inArgMap;
         }

         public string ReplaceFromMap(Match m)
         {
            if (myArgMap.ContainsKey(m.Value))
            {
               return myArgMap[m.Value].mkSafeTypeName();
            }
            return m.Value;
         }
      }

      public static string SubstituteInType(String type, Dictionary<string,TypeRepTemplate> argMap)
      {
         if (String.IsNullOrEmpty(type) || argMap == null)
            return type;

         TypeVarMapper mapper = new TypeVarMapper(argMap);
         return Regex.Replace(type, @"([\w|\.]+)*", new MatchEvaluator(mapper.ReplaceFromMap));
      }

      
      private static string OldSubstituteInType(String type, Dictionary<string,TypeRepTemplate> argMap)
      {
         if (String.IsNullOrEmpty(type))
            return type;

         string ret = type;
         // type is either "string" or "string*[type,type,...]*" or string[]
//         Match match = Regex.Match(type, @"^([\w|\.]+)(?:\s*\*\[\s*([\w|\.]+)(?:\s*,\s*([\w|\.]+))*\s*\]\*)?$");
         Match match = Regex.Match(type, @"([\w|\.]+)*");
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

   public class TypeRepRef
   {

      private class TypeVarMapper
      {
         private Dictionary<string,TypeRepTemplate> myArgMap;
         private TypeRepRef inTy;

         public TypeVarMapper(Dictionary<string,TypeRepTemplate> inArgMap, TypeRepRef ty)
         {
            myArgMap = inArgMap;
            inTy = ty;
         }

         public string ReplaceFromMap(Match m)
         {
            if (myArgMap.ContainsKey(m.Value))
            {
               // If the replacement type is primitive then tell cs2j to use the Boxed version when emitting type. 
               inTy.ForceBoxed = true;
               return myArgMap[m.Value].mkSafeTypeName();
            }
            return m.Value;
         }
      }

      // if ForceBoxed is true then any primitive types should be emitted as the boxed rep.
      private bool _forceBoxed = false;
      [XmlAttribute("box")]
      [System.ComponentModel.DefaultValueAttribute(false)]
      public bool ForceBoxed
      {
         get
         {
            return _forceBoxed;
         }
         set
         {
            _forceBoxed = value;
         }
      }

      private string _type = "";
      [XmlText]
      public string Type
      {
         get
         {
            return _type;
         }
         set
         {
            _type = value.Replace("<","*[").Replace(">","]*");
         }
      }

      public TypeRepRef()
      {
         
      }

      public TypeRepRef(TypeRepRef copyFrom)
      {
         ForceBoxed = copyFrom.ForceBoxed;
         Type = copyFrom.Type;
      }

      public TypeRepRef(string t)
      {
         ForceBoxed = false;
         Type = t;
      }

      public void SubstituteInType(Dictionary<string,TypeRepTemplate> argMap)
      {
         if (!String.IsNullOrEmpty(Type))
         {
            TypeVarMapper mapper = new TypeVarMapper(argMap, this);
            Type = Regex.Replace(Type, @"([\w|\.]+)*", new MatchEvaluator(mapper.ReplaceFromMap));
         }
      }

      // public static implicit operator string(TypeRepRef t) 
      // {
      //    return t.ToString();
      // }

      public override string ToString()
      {
         return Type;
      }

      #region Equality
      public bool Equals (TypeRepRef other)
      {
         if (other == null)
            return false;

         return ForceBoxed == other.ForceBoxed && Type == other.Type;
      }

      public override bool Equals (object obj)
      {
			
         TypeRepRef temp = obj as TypeRepRef;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (TypeRepRef a1, TypeRepRef a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (TypeRepRef a1, TypeRepRef a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         return (Type ?? String.Empty).GetHashCode () ^ ForceBoxed.GetHashCode();
      }
      #endregion
   }
	
   // Simple <type> <name> pairs to represent formal parameters
   public class ParamRepTemplate : IEquatable<ParamRepTemplate>, IApplyTypeArgs
   {
      private TypeRepRef _type = null;
      public TypeRepRef Type { 
         get { return _type; }
         set {
            _type=value;
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

         if (copyFrom.Type != null)
         {
            Type = new TypeRepRef(copyFrom.Type);
         }

         if (!String.IsNullOrEmpty(copyFrom.Name))
         {
            Name = copyFrom.Name;
         }
         IsByRef = copyFrom.IsByRef;
      }

      public ParamRepTemplate (string t, string a)
      {
         Type = new TypeRepRef(t);
         Name = a;
         IsByRef = false;
      }

      public ParamRepTemplate (string t, string a, bool isbyref)
      {
         Type = new TypeRepRef(t);
         Name = a;
         IsByRef = isbyref;
      }

      public void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         Type.SubstituteInType(args);
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
         int hashCode = Type != null ? Type.GetHashCode() : 0;

         return hashCode ^ (Name ?? String.Empty).GetHashCode () ^ IsByRef.GetHashCode();
      }
      #endregion
   }

   // Represents a variable number of parameters
   public class ParamArrayRepTemplate : ParamRepTemplate, IEquatable<ParamArrayRepTemplate>
   {

      public ParamArrayRepTemplate ()
      {
      }

      public ParamArrayRepTemplate(ParamArrayRepTemplate copyFrom) : base(copyFrom)
      {
      }

      public ParamArrayRepTemplate (string t, string a) : base(t, a)
      {
      }

      #region Equality
      public bool Equals (ParamArrayRepTemplate other)
      {
         return base.Equals(other);
      }

      public override bool Equals (object obj)
      {
			
         ParamArrayRepTemplate temp = obj as ParamArrayRepTemplate;
			
         if (!Object.ReferenceEquals (temp, null))
            return this.Equals (temp);
         return false;
      }

      public static bool operator == (ParamArrayRepTemplate a1, ParamArrayRepTemplate a2)
      {
         return Object.Equals (a1, a2);
      }

      public static bool operator != (ParamArrayRepTemplate a1, ParamArrayRepTemplate a2)
      {
         return !(a1 == a2);
      }

      public override int GetHashCode ()
      {
         return base.GetHashCode ();
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
		
      // Emit this warning if we use this translation
      protected string _warning = null; 		
      public virtual string Warning { 
         get { return _warning; }
         set { _warning = value; } 
      }
		
      // Optional,  but if present will let mkJava generate better java guess in some cases
      private TypeRepTemplate _surroundingType;
      [XmlIgnore]
      public TypeRepTemplate SurroundingType { 
         get { return _surroundingType; }
         set {
            _surroundingType=value;
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

      protected TranslationBase(TypeRepTemplate parent, TranslationBase copyFrom)
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

         if (!String.IsNullOrEmpty(copyFrom.Warning))
         {
            Warning = copyFrom.Warning;
         }

         SurroundingType = parent;
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


      protected string mkJavaParams(IList<ParamRepTemplate> pars, ParamArrayRepTemplate paramarr) {
         StringBuilder parStr = new StringBuilder();
         parStr.Append("(");
         foreach (ParamRepTemplate p in pars) {
            parStr.Append("${"+p.Name+"},");
         }
         if (parStr[parStr.Length-1] == ',') {
            // remove trailing comma
            parStr.Remove(parStr.Length-1,1);
         }
         if (paramarr != null)
         {
            // ${*]n} means all parameters with position (1,2,..) greater than n
            // so ${*]0} means all arguments, ${*]1} means all but first etc.
            parStr.Append("${" + (pars.Count > 0 ? "," : "") + "*]"+pars.Count.ToString()+"}");
         }
         parStr.Append(")");
         return parStr.ToString();
      }
      protected string mkTypeParams(String[] pars) {
         StringBuilder parStr = new StringBuilder();
         parStr.Append("*[");
         foreach (string p in pars) {
            parStr.Append("${"+p+"},");
         }
         if (parStr[parStr.Length-1] == ',') {
            parStr.Remove(parStr.Length-1,1);
         }
         parStr.Append("]*");
         return parStr.ToString();
      }

      // Instantiate type arguments
      public virtual void Apply(Dictionary<string,TypeRepTemplate> args)
      {
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
			
         return Java == other.Java && Warning == other.Warning;
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
         return (Java ?? String.Empty).GetHashCode () ^ (Warning ?? String.Empty).GetHashCode () ^ hashCode;
      }
      #endregion
		
   }
   
   public class IterableRepTemplate : TranslationBase, IEquatable<IterableRepTemplate>
   {

      public TypeRepRef ElementType {
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
         ElementType = new TypeRepRef(ty);
      }

      public IterableRepTemplate(TypeRepTemplate parent, IterableRepTemplate copyFrom)
         : base(parent, copyFrom)
      {
         if (copyFrom != null)
         {
            ElementType = new TypeRepRef(copyFrom.ElementType);
         }
      }

      public IterableRepTemplate (String ty, string[] imps, string javaRep) : base(imps, javaRep)
      {
         ElementType = new TypeRepRef(ty);
      }


      public override void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         if (ElementType != null)
         {
            ElementType.SubstituteInType(args);
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
         int hashCode = ElementType != null ? ElementType.GetHashCode() : 0;

         return hashCode ^ base.GetHashCode ();
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
		
      private ParamArrayRepTemplate _paramArray = null;
      public ParamArrayRepTemplate ParamArray {
         get
         {
            return _paramArray;
         }
         set
         {
            _paramArray = value;
         }

      }
		
      public override string mkJava() {
         string constructorName = "CONSTRUCTOR";
         if (SurroundingType != null) {
            constructorName = SurroundingType.TypeName.Substring(SurroundingType.TypeName.LastIndexOf('.') + 1);
            if (SurroundingType.TypeParams != null && SurroundingType.TypeParams.Length > 0)
            {
                constructorName += mkTypeParams(SurroundingType.TypeParams);
            }
         }
         return "new " + constructorName + mkJavaParams(Params, ParamArray);
      }
		
      public override string[] mkImports() {
         if (SurroundingType != null) {
            return new string[] {SurroundingType.TypeName};
         }
         else {
            return null;
         }
      }

      public ConstructorRepTemplate()
         : base()
      {
      }

      public ConstructorRepTemplate(TypeRepTemplate parent, ConstructorRepTemplate copyFrom)
         : base(parent, copyFrom)
      {
         foreach (ParamRepTemplate p in copyFrom.Params)
         {
            Params.Add(new ParamRepTemplate(p));
         }
         ParamArray = copyFrom.ParamArray;
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
         if (ParamArray != null)
            ParamArray.Apply(args);
         
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

         if (ParamArray != other.ParamArray)
            return false;

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
			
         return base.GetHashCode () ^ hashCode ^ (ParamArray == null ? 0 : ParamArray.GetHashCode());
      }
      #endregion
   }

   // Method has the same info as a delegate as a constructor plus a name and return type
   public class MethodRepTemplate : ConstructorRepTemplate, IEquatable<MethodRepTemplate>
   {
      // Method name
      public string Name { get; set; }

      // Method name in Java (defaults to Name)
      private string _javaName = null;
      public string JavaName { 
         get
         {
            return (_javaName == null || _javaName.Length == 0) ? Name : _javaName; 
         }
         set
         {
            _javaName = value;
         }
      }

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
      private TypeRepRef _return = new TypeRepRef();
      public TypeRepRef Return { 
         get { return _return; }
         set {
            _return=value;
         }
      }		

      // isStatic method?
      private bool _isStatic = false;
      [XmlAttribute("static")]
      [System.ComponentModel.DefaultValueAttribute(false)]
      public bool IsStatic { 
         get 
         {
            return _isStatic;
         }
         set
         {
            _isStatic = value;
         }
      }

      private bool _isPartialDefiner = false;
      [XmlAttribute("partial")]
      [System.ComponentModel.DefaultValueAttribute(false)]
      public bool IsPartialDefiner { 
         get 
         {
            return _isPartialDefiner;
         }
         set
         {
            _isPartialDefiner = value;
         }
      }

      public MethodRepTemplate()
      {
         IsStatic = false;
         IsPartialDefiner = false;
      }

      public MethodRepTemplate(TypeRepTemplate parent, MethodRepTemplate copyFrom) : base(parent, copyFrom)
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
         Return = new TypeRepRef(copyFrom.Return);

         IsStatic = copyFrom.IsStatic;
         IsPartialDefiner = copyFrom.IsPartialDefiner;
      }

      public MethodRepTemplate(string retType, string methodName, string[] tParams, List<ParamRepTemplate> pars, string[] imps, string javaRep)
         : base(pars, imps, javaRep)
      {
         Name = methodName;
         TypeParams = tParams;
         Return = new TypeRepRef(retType);
         IsStatic = false;
         IsPartialDefiner = false;
      }

      public MethodRepTemplate (string retType, string methodName, string[] tParams, List<ParamRepTemplate> pars) : this(retType, methodName, tParams, pars, null, null)
      {
      }
		
      public override string[] mkImports() {
         if (IsStatic && SurroundingType != null) {
            return new string[] {SurroundingType.TypeName};
         }
         else {
            return null;
         }
      }	
		
      public override string mkJava() {
         StringBuilder methStr = new StringBuilder();

         // if we only have the definition, not the implementation, then don't emit any calls in the Java
         if (IsPartialDefiner)
         {
            return String.Empty;
         }

         if (IsStatic) {
            if (SurroundingType != null) {
               methStr.Append(SurroundingType.TypeName.Substring(SurroundingType.TypeName.LastIndexOf('.') + 1) + ".");
            }
            else {
               methStr.Append("TYPENAME.");
            }
         }
         else {
            methStr.Append("${this:16}.");
         }

         methStr.Append(JavaName);
         
         return methStr.ToString() + mkJavaParams(Params, ParamArray);
      }
		
      // TODO: filter out redefined type names
      public override void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         if (Return != null)
         {
            Return.SubstituteInType(args);
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
			
         return Return == other.Return && Name == other.Name && JavaName == other.JavaName && IsStatic == other.IsStatic && IsPartialDefiner == other.IsPartialDefiner && base.Equals(other);
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

         hashCode = hashCode ^ (Return != null ? Return.GetHashCode() : 0);


         return hashCode ^ (Name ?? String.Empty).GetHashCode () ^ (JavaName ?? String.Empty).GetHashCode () ^ IsStatic.GetHashCode() ^ IsPartialDefiner.GetHashCode() ^ base.GetHashCode();
      }
      #endregion

   }

   public class InvokeRepTemplate : MethodRepTemplate
   {
      public InvokeRepTemplate()
      {
      }

      public InvokeRepTemplate(TypeRepTemplate parent, MethodRepTemplate copyFrom) 
        : base(parent, copyFrom)
      {
      }

      public InvokeRepTemplate (string retType, string methodName, string[] tParams, List<ParamRepTemplate> pars) : base(retType, methodName, tParams, pars)
      {
      }

//      public override string mkJava()
//      {
//         return "${this:16}.Invoke" +  mkJavaParams(this.Params);
//      }
   }

   //  A user-defined cast from one type to another
   public class CastRepTemplate : TranslationBase, IEquatable<CastRepTemplate>
   {
      // From and To are fully qualified types
      private TypeRepRef _from;
      public TypeRepRef From { 
         get { return _from; }
         set {
            _from = value; 
         }
      }		

      private TypeRepRef _to;
      public TypeRepRef To { 
         get { return _to; }
         set {
            _to= value;
         }
      }


      public CastRepTemplate()
         : base()
      {
      }

      public CastRepTemplate(TypeRepTemplate parent, CastRepTemplate copyFrom)
         : base(parent, copyFrom)
      {
         if (copyFrom.From != null)
         {
            From = new TypeRepRef(copyFrom.From);
         }
         if (copyFrom.To != null)
         {
            To = new TypeRepRef(copyFrom.To);
         }

      }

      public CastRepTemplate (string fType, string tType, string[] imps, string java) : base(imps, java)
      {
         From = new TypeRepRef(fType);
         To = new TypeRepRef(tType);
      }

      public CastRepTemplate (string fType, string tType) : this(fType, tType, null, null)
      {
      }
		
      public override string[] mkImports() {
         if (SurroundingType != null) {
            return new string[] {SurroundingType.TypeName};
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
            if (SurroundingType != null) {
               String myType = SurroundingType.TypeName.Substring(SurroundingType.TypeName.LastIndexOf('.') + 1);
               String toType = To.Type.Substring(To.Type.LastIndexOf('.') + 1);
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
               return "__cast_" + To.Type.Replace('.','_') + "(${expr})";
            }
         }
      }

      public override void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         if (From != null)
         {
            From.SubstituteInType(args);
         }
         if (To != null)
         { 
            To.SubstituteInType(args);
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
         int hashCode = From != null ? From.GetHashCode() : 0;
         hashCode = hashCode ^ (To != null ? To.GetHashCode() : 0);


         return hashCode ^ base.GetHashCode();
      }
      #endregion
		
   }

   // A member field definition
   public class FieldRepTemplate : TranslationBase, IEquatable<FieldRepTemplate>
   {

      private TypeRepRef _type;
      public TypeRepRef Type { 
         get { return _type; }
         set {
            _type=value;
         }
      }		
      public string Name { get; set; }

      public FieldRepTemplate()
         : base()
      {
      }

      public FieldRepTemplate(TypeRepTemplate parent, FieldRepTemplate copyFrom)
         : base(parent, copyFrom)
      {
         if (!String.IsNullOrEmpty(copyFrom.Name))
         {
            Name = copyFrom.Name;
         }
         if (copyFrom.Type != null)
         {
            Type = new TypeRepRef(copyFrom.Type);
         }
      }

      public FieldRepTemplate(string fType, string fName, string[] imps, string javaGet)
         : base(imps, javaGet)
      {
         Type = new TypeRepRef(fType);
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
            Type.SubstituteInType(args);
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
         int hashCode = Type != null ? Type.GetHashCode() : 0;
         return hashCode ^ (Name ?? String.Empty).GetHashCode() ^ base.GetHashCode();
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
                
/*
      public override string Java
      {
         get
         {
            return JavaGet;
         }
      }
      */

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

      public PropRepTemplate(TypeRepTemplate parent, PropRepTemplate copyFrom)
         : base(parent, copyFrom)
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
         return JavaGet;
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
		
      private ParamArrayRepTemplate _paramArray = null;
      public ParamArrayRepTemplate ParamArray {
         get {
            return _paramArray;
         }
         set {
            _paramArray = value;
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
               _setParams.Add(new ParamRepTemplate(Type.Type,"value"));
            }
            return _setParams;
         }
      }
		
      private ParamArrayRepTemplate _setParamArray = null;
      public ParamArrayRepTemplate SetParamArray {
         get {
            if (_setParamArray == null)
            {
               return ParamArray;
            }
            else
            {
               return _setParamArray;
            }
         }
         set {
            _setParamArray = value;
         }
      }
		
      [XmlElementAttribute("Get")]
      public override string JavaGet {
         get {
            if (!CanRead) return null;
            if (_javaGet == null) {
               if (_java == null) {
                  return (CanRead ? "${this:16}.get___idx" + mkJavaParams(Params, ParamArray) : null);
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
               return (CanWrite ? "${this:16}.set___idx" + mkJavaParams(SetParams, SetParamArray): null);
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

      public IndexerRepTemplate(TypeRepTemplate parent, IndexerRepTemplate copyFrom)
         : base(parent, copyFrom)
      {
         foreach (ParamRepTemplate p in copyFrom.Params)
         {
            Params.Add(new ParamRepTemplate(p));
         }
         if (copyFrom._setParams != null)
         {
            foreach (ParamRepTemplate p in copyFrom._setParams)
            {
               SetParams.Add(new ParamRepTemplate(p));
            }
         }

         _paramArray = copyFrom._paramArray;
         _setParamArray = copyFrom._setParamArray;

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

         if (_paramArray != null)
            _paramArray.Apply(args);
         if (_setParamArray != null)
            _setParamArray.Apply(args);

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

         if (ParamArray != other.ParamArray)
            return false;

         if (SetParamArray != other.SetParamArray)
            return false;

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
			
         return base.GetHashCode () ^ hashCode ^  (ParamArray == null ? 0 : ParamArray.GetHashCode()) ^ (_setParamArray == null ? 0 : _setParamArray.GetHashCode());
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
      public EnumMemberRepTemplate(TypeRepTemplate parent, EnumMemberRepTemplate copyFrom)
         : base(parent, copyFrom)
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
      private string _variant = "";
      // Translation Variant
      [XmlAttribute("variant")]
      [System.ComponentModel.DefaultValueAttribute("")]
      public string Variant { 
         get
         {
            if (_variant == null)
            {
               _variant = "";
            }
            return _variant;
         }
         set
         {
            _variant = value;
         }
      }

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

      protected string[] _uses;
      // Path to use when resolving types
      [XmlArrayItem("Use")]
      public string[] Uses { get{return _uses;} set { _uses = value; updateUsesWithNamespace(); } }

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

      // Set if value is wrapped in a RefSupport object (used for ref and out params) 
      private bool _isWrapped = false;
      [XmlIgnore]
      public bool IsWrapped
      {
         get
         {
            return _isWrapped;
         }
         set
         {
            _isWrapped = value;
         }
      }

      // Client can set _isUnboxedType.  If so then we know the expression / type is unboxed 
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

      private String _boxedJava = null;
      public String BoxedJava {
         get
         {
            if (String.IsNullOrEmpty(_boxedJava))
            {
               _boxedJava = Java; 
            }
            return _boxedJava;
         }
         set
         {
            _boxedJava = value;
         }
      }

      // True if we have a separate representation for boxed and unboxed versions
      // (true for primitive types like int)
      private bool hasBoxedRep = false;
      [XmlAttribute("has_boxed_rep")]
      [System.ComponentModel.DefaultValueAttribute(false)]
      public bool HasBoxedRep
      {
         get
         {
            return hasBoxedRep;
         }
         set
         {
            hasBoxedRep = value;
         }
      }

      [XmlIgnore]
      public string BoxExpressionTemplate
      {
         get
         {
            return (String.IsNullOrEmpty(BoxedJava) ? "" : "((" + BoxedJava + ")${expr})");
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

      // Ugly, keep a copy of the tree. Its convenient if these are passed around with the type
      private object _tree = null;
      [XmlIgnore]
      public object Tree
      {
         get
         {
            return _tree;
         }
         set
         {
            _tree = value;
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
         :base(null, copyFrom)
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
               InstantiatedTypes[i] = copyFrom.InstantiatedTypes[i];
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
            Casts.Add(new CastRepTemplate(this, c));
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
         Variant = copyFrom.Variant;
         BoxedJava = copyFrom.BoxedJava;
         HasBoxedRep = copyFrom.HasBoxedRep;
         Tree = copyFrom.Tree;
      }

      protected TypeRepTemplate(string tName, string[] tParams, string[] usePath, AliasRepTemplate[] aliases, string[] imports, string javaTemplate)
         : base(imports, javaTemplate)
      {
         TypeName = tName;
         TypeParams = tParams;
         Uses = usePath;
         Aliases = aliases;
      }

      public void updateUsesWithNamespace()
      {
          int ni = -1;
          if (!String.IsNullOrEmpty(TypeName) && (ni = TypeName.LastIndexOf('.')) > 0)
          {
              List<String> namespaces = null;
              String ns1 = TypeName.Substring(0, ni); 
              while (true)
              {
                  if (namespaces == null)
                  {
                      if (_uses == null || Array.IndexOf(_uses,ns1)<0)
                      {
                          namespaces = new List<string>(_uses);
                          namespaces.Add(ns1);
                      }
                  }
                  else
                  {
                      if (!namespaces.Contains(ns1)) namespaces.Add(ns1);
                  }
                  
                  ni = ns1.LastIndexOf('.');
                  if (ni <= 0) break;
                  ns1 = ns1.Substring(0, ni);
              }
              if (namespaces != null)
                 _uses = namespaces.ToArray();
          }
      }
      public override string mkJava() {
         string ret = String.Empty;
         if (TypeName != null && TypeName != String.Empty) {
             ret = TypeName.Substring(TypeName.LastIndexOf('.') + 1);
             if (TypeParams != null && TypeParams.Length > 0)
             {
                 ret += mkTypeParams(TypeParams);
             }
         }
         return ret;
      }

      public override string[] mkImports() {
         if (TypeName !=  null) {
            return new string[] {TypeName};
         }
         else {
            return null;
         }
      }
             
      protected Dictionary<string,TypeRepTemplate> mkTypeMap(ICollection<TypeRepTemplate> args) { 
         Dictionary<string,TypeRepTemplate> ret = new Dictionary<string,TypeRepTemplate>();
         if (args == null)
         {
             return ret;
         }
         if (args.Count == TypeParams.Length)
         {
            int i = 0;
            foreach (TypeRepTemplate sub in args)
            {   
               ret[TypeParams[i]] = sub;   
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
         InstantiatedTypes = new TypeRepTemplate[InstantiatedTypes.Length];
         if (args != null) {
            for (int i = 0; i < TypeParams.Length; i++)
            {
                 InstantiatedTypes[i] = args[TypeParams[i]];
            }
         }
         BoxedJava = TemplateUtilities.SubstituteInType(BoxedJava,args);
         base.Apply(args);
      }

      public ResolveResult Resolve(String name, IList<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv)
      {
          ResolveResult res = Resolve(name, args, AppEnv, false);
          if (TemplateUtilities.DO_IMPLICIT_CASTS &&  res == null) res = Resolve(name, args, AppEnv, true);
          return res;
      }
      // Resolve a method call (name and arg types)
      public virtual ResolveResult Resolve(String name, IList<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv, bool implicitCast)
      {
         if (Inherits != null)
         {
            foreach (String b in Inherits)
            {
               TypeRepTemplate baseType = BuildType(b, AppEnv);
               if (baseType != null)
               {
                  ResolveResult ret = baseType.Resolve(name,args,AppEnv,implicitCast);
                  if (ret != null)
                     return ret;
               }
            }
         }
         return null;
      }
       public ResolveResult Resolve(String name, bool forWrite, DirectoryHT<TypeRepTemplate> AppEnv)
      {
          ResolveResult res = Resolve(name, forWrite, AppEnv, false);
          if (TemplateUtilities.DO_IMPLICIT_CASTS && res == null) res = Resolve(name, forWrite, AppEnv, true);
          return res;
      }
      // Resolve a field or property access
      public virtual ResolveResult Resolve(String name, bool forWrite, DirectoryHT<TypeRepTemplate> AppEnv, bool implicitCast)
      {
         if (Inherits != null)
         {
            foreach (String b in Inherits)
            {
               TypeRepTemplate baseType = BuildType(b, AppEnv);
               if (baseType != null)
               {
                  ResolveResult ret = baseType.Resolve(name, forWrite, AppEnv,implicitCast);
                  if (ret != null)
                     return ret;
               }
            }
         }
         return null;
      }

      public ResolveResult ResolveIndexer(IList<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv)
      {
          ResolveResult res = ResolveIndexer(args, AppEnv, false);
          if (TemplateUtilities.DO_IMPLICIT_CASTS && res == null) res = ResolveIndexer(args, AppEnv, true);
          return res;
      }
      // Resolve a indexer call (arg types)
      public virtual ResolveResult ResolveIndexer(IList<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv, bool implicitCast)
      {
         if (Inherits != null)
         {
            foreach (String b in Inherits)
            {
               TypeRepTemplate baseType = BuildType(b, AppEnv);
               if (baseType != null)
               {
                  ResolveResult ret = baseType.ResolveIndexer(args,AppEnv,implicitCast);
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
                     if ((toTy.IsA(castTo, AppEnv,false) && castTo.IsA(toTy, AppEnv,false)) || (toTy.IsA(castTo, AppEnv,true) && castTo.IsA(toTy, AppEnv,true)) )
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
                     if ((castFrom.IsA(fromTy, AppEnv,false) && fromTy.IsA(castFrom, AppEnv,false)) || (castFrom.IsA(fromTy, AppEnv,true) && fromTy.IsA(castFrom, AppEnv,true)))
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

      private List<string> primitiveTypes = null;
      private List<string> PrimitiveTypes
      {
          get
          {
              if (primitiveTypes == null)
              {
                  primitiveTypes = new List<string>();
                  primitiveTypes.Add("System.Boolean");
                  primitiveTypes.Add("System.Byte");
                  primitiveTypes.Add("System.Char");
                  primitiveTypes.Add("System.Decimal");
                  primitiveTypes.Add("System.Single");
                  primitiveTypes.Add("System.Double");
                  primitiveTypes.Add("System.Int32");
                  primitiveTypes.Add("System.Int64");
                  primitiveTypes.Add("System.SByte");
                  primitiveTypes.Add("System.Int16");
                  primitiveTypes.Add("System.String");
                  primitiveTypes.Add("System.UInt32");
                  primitiveTypes.Add("System.UInt64");
                  primitiveTypes.Add("System.UInt16");
                  primitiveTypes.Add("System.Void");

                  primitiveTypes.Add("System.Enum");

                  primitiveTypes.Add("long");
                  primitiveTypes.Add("int");
                  primitiveTypes.Add("short");
                  primitiveTypes.Add("byte");

                  primitiveTypes.Add("ulong");
                  primitiveTypes.Add("uint");
                  primitiveTypes.Add("ushort");
                  primitiveTypes.Add("sbyte");

                  primitiveTypes.Add("double");
                  primitiveTypes.Add("float");
              }
              return primitiveTypes;
          }
      }

      public bool IsObject(DirectoryHT<TypeRepTemplate> AppEnv)
      {
          /*
           * Test part
           */
          bool debug = true;
          string type = this.TypeName.Split('?')[0];

          bool found = PrimitiveTypes.Contains(type);
          if (!found && Inherits!=null)
          {
            foreach (String ibase in Inherits)
            {
               TypeRepTemplate tbase = BuildType(ibase, AppEnv, new UnknownRepTemplate(ibase));
               if (!tbase.IsObject(AppEnv))
               {
                   found = true;
                   Console.WriteLine("FOUND : " + ibase + " in "+ type);
               }
            }
         }
          if (debug)
          {
              string[] typeSplit = type.Split('.');

              List<string> weirdFinals = new List<string>();
              weirdFinals.Add("APPLY");
              weirdFinals.Add("INDEXER");

              string inheritsString = "";
              foreach (string inherit in this.Inherits)
                  inheritsString += " | " + inherit;

              if ((weirdFinals.Contains(typeSplit[typeSplit.Length - 1]) || typeSplit.Length == 1) && type.StartsWith("_"))
              {
                  Console.WriteLine("TYPE : " + type);
                  Console.WriteLine(found ? "I've found " + type + " in the list !" : "Nope, sorry, not in the list : " + type + " but this is its inherits : " + inheritsString);
              }
          }

          else
          {
              Console.WriteLine("TYPE : " + type);
              Console.WriteLine(found ? "I've found " + type + " in the list !" : "Nope, sorry, not in the list : " + type);

          }
         return !found;
      }
      
      Dictionary<String, String[]> implicitCasts = new Dictionary<string, string[]>()
      {
          {"System.SByte" , new String[] {"System.Int16","System.Int32","System.Int64","System.Float","System.Double","System.Decimal"}},
          {"System.Byte" , new String[] {"System.Int16","System.UInt16","System.Int32","System.UInt32","System.Int64","System.UInt64","System.Float","System.Double","System.Decimal"}},
          {"System.Int16" , new String[] {"System.Int32","System.Int64","System.Float","System.Double","System.Decimal"}},
          {"System.UInt16" , new String[] {"System.Int32","System.UInt32","System.Int64","System.UInt64","System.Float","System.Double","System.Decimal"}},
          {"System.Int32" , new String[] {"System.Int64","System.Float","System.Double","System.Decimal"}},
          {"System.UInt32" , new String[] {"System.Int64","System.UInt64","System.Float","System.Double","System.Decimal"}},
          {"System.Int64" , new String[] {"System.Float","System.Double","System.Decimal"}},
          {"System.UInt64" , new String[] {"System.Float","System.Double","System.Decimal"}},
          {"System.Char" , new String[] {"System.UInt16","System.Int32","System.UInt32","System.Int64","System.UInt64","System.Float","System.Double","System.Decimal"}},
          {"System.Float" , new String[] {"System.Double","System.Decimal"}},
      };
      // Returns true if other is a subclass, or implements our interface
      public virtual bool IsA(TypeRepTemplate other, DirectoryHT<TypeRepTemplate> AppEnv)
      {
          return IsA(other, AppEnv, false);
      }
      public virtual bool IsA (TypeRepTemplate other, DirectoryHT<TypeRepTemplate> AppEnv, bool implicitCast) {
         if (this.IsExplicitNull) 
         {
            return true;
         }

        /*
         * We avoid the nullable types
         */
         string otherType = other.TypeName.Split('?')[0];
         string thisType = this.TypeName.Split('?')[0];

          /*
           * We TEMPORARILY use this
           * 
           * We remove namespaces from types before to test the equality
           * (to avoid foo.bar.Foobar != Foobar)
           *

         string[] tempOtherType = otherType.Split('.');
         string[] tempThisType = thisType.Split('.');

         otherType = tempOtherType[tempOtherType.Length - 1];
         thisType = tempThisType[tempThisType.Length - 1];
          */
         if (otherType == thisType)
         {
            // See if generic arguments 'match'
            if (InstantiatedTypes != null && other.InstantiatedTypes != null && InstantiatedTypes.Length == other.InstantiatedTypes.Length)
            {
               bool isA = true;
               for (int i = 0; i < InstantiatedTypes.Length; i++)
               {
                  if (!InstantiatedTypes[i].IsA(other.InstantiatedTypes[i],AppEnv,false))
                  {
                     isA = false;
                     break;
                  }
               }
               return isA;
            }
            else
            {
                // might be equal if they both represent "nothing"
                return (InstantiatedTypes == null && (other.InstantiatedTypes == null || other.InstantiatedTypes.Length == 0)) ||
                     (other.InstantiatedTypes == null && (InstantiatedTypes == null || InstantiatedTypes.Length == 0));
            }
         }
         else if (Inherits != null)
         {
            foreach (String ibase in Inherits)
            {
               TypeRepTemplate tbase = BuildType(ibase, AppEnv, new UnknownRepTemplate(ibase));
               if (tbase.IsA(other,AppEnv,implicitCast))
               {
                  return true;
               }
            }
         }
          //Implicit cast : Stripped down version, returns the first that matches
         if (TemplateUtilities.DO_IMPLICIT_CASTS && implicitCast && this.Inherits != null && Array.IndexOf(this.Inherits, "System.Number") >= 0 && other.Inherits != null && Array.IndexOf(other.Inherits, "System.Number") >= 0)
        {
            String[] implicitCastTypes;
            if (implicitCasts.TryGetValue(this.TypeName, out implicitCastTypes) && Array.IndexOf(implicitCastTypes, other.TypeName)>=0) return true;
        }
         return false;
      }

      private class ParseResult<T>
      {
         public ParseResult(List<T> inParses, String inStr)
         {
            Parses = inParses;
            RemainingStr = inStr;
         }
         public List<T> Parses;
         public String RemainingStr;
      }

      // returns a list of type reps from a string representation:
      // <qualified.type.name>(*[<type>, <type>, ...]*)?([])*, .....
      private ParseResult<TypeRepTemplate> buildTypeList(string typeList, DirectoryHT<TypeRepTemplate> AppEnv)
      {
         List<TypeRepTemplate> types = new List<TypeRepTemplate>();
         string typeStr = typeList.TrimStart();
         bool moreTypes = true;
         while (moreTypes)
         {
            // get type name from the start
            int nameEnd = typeStr.IndexOfAny(new char[] { '*','[',']',','});    
            string typeName = typeStr.Substring(0,(nameEnd >= 0 ? nameEnd : typeStr.Length)).TrimEnd();
            typeStr = typeStr.Substring(typeName.Length).TrimStart();

            // build basetype
            TypeRepTemplate typeRep = null;

            // Is it a type var?
            foreach (string p in TypeParams) {
               if (p == typeName)
               {
                  typeRep = new TypeVarRepTemplate(typeName);
                  break;
               }    
            }   
            if (typeRep == null)
            {
               // Not a type var, look for a type
               List<TypeRepTemplate> tyArgs = new List<TypeRepTemplate>();

               // Do we have type arguments?
               if (typeStr.Length > 0 && typeStr.StartsWith("*["))
               {
                  // isolate type arguments
                  ParseResult<TypeRepTemplate> args = buildTypeList(typeStr.Substring(2), AppEnv);
                  tyArgs = args.Parses;
                  typeStr = args.RemainingStr.TrimStart();
                  if (typeStr.StartsWith("]*"))
                  {
                     typeStr = typeStr.Substring(2).TrimStart();
                  }
                  else
                  {
                     throw new Exception("buildTypeList: Cannot parse " + types);
                  }
               }
                /*
                //Add Uses
                List<String> namespaces = new List<string>(this.Uses);
                String ns1=this.TypeName;
                while (true)
                {
                    int ni = ns1.LastIndexOf('.');
                    if (ni <= 0) break;
                    ns1 = ns1.Substring(0,ni);
                    if (!namespaces.Contains(ns1)) namespaces.Add(ns1);
                }
               typeRep = AppEnv.Search(namespaces.ToArray(), typeName + (tyArgs.Count > 0 ? "'" + tyArgs.Count.ToString() : ""), new UnknownRepTemplate(typeName));*/
               typeRep = AppEnv.Search(this.Uses, typeName + (tyArgs.Count > 0 ? "'" + tyArgs.Count.ToString() : ""), new UnknownRepTemplate(typeName));
               if (!typeRep.IsUnknownType && tyArgs.Count > 0)
               {
                   typeRep = typeRep.Instantiate(tyArgs);
               }
            }
         
            // Take care of arrays ....
            while (typeStr.StartsWith("[]"))
            {
               TypeRepTemplate arrayType = AppEnv.Search("System.Array'1", new UnknownRepTemplate("System.Array'1"));
               typeRep = arrayType.Instantiate(new TypeRepTemplate[] { typeRep });
               typeStr = typeStr.Substring(2).TrimStart();
            }
            types.Add(typeRep);
            moreTypes = typeStr.StartsWith(",");
            if (moreTypes)
            {
               typeStr = typeStr.Substring(1).TrimStart();
            }
         } 
         return new ParseResult<TypeRepTemplate>(types, typeStr);
      }
		
      // Builds a type rep from a string representation
      // "type_name"
      // "<type>[]"
      // "<type>[<type>, ...]"
      public TypeRepTemplate BuildType(TypeRepRef typeRep, DirectoryHT<TypeRepTemplate> AppEnv)
      {
         return BuildType(typeRep.Type, AppEnv, null);
      }
      public TypeRepTemplate BuildType(string typeRep, DirectoryHT<TypeRepTemplate> AppEnv)
      {
         return BuildType(typeRep, AppEnv, null);
      }

      public TypeRepTemplate BuildType(TypeRepRef typeRep, DirectoryHT<TypeRepTemplate> AppEnv, TypeRepTemplate def)
      {
         return BuildType(typeRep.Type, AppEnv, def);
      }

      public TypeRepTemplate BuildType(string typeRep, DirectoryHT<TypeRepTemplate> AppEnv, TypeRepTemplate def)
      {

         if (String.IsNullOrEmpty(typeRep))
            return def;
         ParseResult<TypeRepTemplate> parseTypes = buildTypeList(typeRep, AppEnv);
         if (parseTypes.Parses != null && parseTypes.Parses.Count == 1 && 
             String.IsNullOrEmpty(parseTypes.RemainingStr.Trim()))
         {
            return parseTypes.Parses.ToArray()[0] ?? def;
         }
         else
         {
            return def;
         }
      }

      #region deserialization
		
      private static XmlReaderSettings _templateReaderSettings = null;

      /// <summary>
      /// Reader Settings used when reading translation templates.  Validate against schemas   
      /// </summary>
      public static XmlReaderSettings TemplateReaderSettings
      {
         get
         {
            if (_templateReaderSettings == null)
            {
               _templateReaderSettings = new XmlReaderSettings();
               _templateReaderSettings.ValidationType = ValidationType.Schema;
               _templateReaderSettings.ValidationFlags |= XmlSchemaValidationFlags.ReportValidationWarnings;
               _templateReaderSettings.ValidationEventHandler += new ValidationEventHandler(ValidationCallBack);
            }
            return _templateReaderSettings;
         }
      }

      // Display any warnings or errors while validating translation templates.
      private static void ValidationCallBack(object sender, ValidationEventArgs args)
      {
         if (args.Severity == XmlSeverityType.Warning)
            Console.WriteLine("\tWarning: Matching schema not found.  No validation occurred." + args.Message);
         else
            Console.WriteLine("\tValidation error: " + args.Message);
      }

      private static object Deserialize (Stream fs, System.Type t)
      {
         object o = null;
	
         // Create the XmlReader object.
         // XmlReader reader = XmlReader.Create(fs, TemplateReaderSettings);
		
         XmlSerializer serializer = new XmlSerializer (t, Constants.TranslationTemplateNamespace);
         //o = serializer.Deserialize (reader);
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

         return IsExplicitNull == other.IsExplicitNull && IsUnboxedType == other.IsUnboxedType && 
                TypeName == other.TypeName && Variant == other.Variant && BoxedJava == other.BoxedJava && base.Equals(other);
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

         return (Java ?? String.Empty).GetHashCode() ^ IsExplicitNull.GetHashCode() ^ IsUnboxedType.GetHashCode() ^ 
            Variant.GetHashCode() ^ BoxedJava.GetHashCode() ^ hashCode;
      }
      #endregion		
		
      public string mkFormattedTypeName(bool incNameSpace, string langle, string rangle)
      {
         StringBuilder fmt = new StringBuilder();
         if (TypeName == "System.Array")
         {
            fmt.Append(InstantiatedTypes[0].mkFormattedTypeName(incNameSpace, langle, rangle));
            fmt.Append("[]");
         }
         else
         {
            fmt.Append(TypeName.Substring(incNameSpace ? 0 : TypeName.LastIndexOf('.')+1));
            if (InstantiatedTypes != null && InstantiatedTypes.Length > 0)
            {
               bool isFirst = true;
               fmt.Append(langle);
               foreach (TypeRepTemplate t in InstantiatedTypes)
               {
                  if (!isFirst)
                     fmt.Append(", ");
                  fmt.Append(t.mkFormattedTypeName(incNameSpace, langle, rangle));
                  isFirst = false;
               }
               fmt.Append(rangle);
            }
         }
         return fmt.ToString(); 
      }

      public string mkFormattedTypeName()
      {
         return mkFormattedTypeName(true, "<", ">");
      }

      public string mkSafeTypeName()
      {
         return mkFormattedTypeName(true, "*[", "]*");
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
               kast.From = new TypeRepRef("System.Int32");
               kast.Java = "${TYPEOF_totype:16}.values()[${expr}]";
               _enumCasts.Add(kast);
               kast = new CastRepTemplate();
               kast.To = new TypeRepRef("System.Int32");
               kast.Java = "((Enum)${expr}).ordinal()";
               _enumCasts.Add(kast);
            }
            return _enumCasts;
         }
      }

      [XmlArrayItem("Cast")]
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
            Members.Add(new EnumMemberRepTemplate(this, m));
         }
      }

      public EnumRepTemplate (List<EnumMemberRepTemplate> ms) : base()
      {
         _members = ms;
      }

      public override ResolveResult Resolve(String name, bool forWrite, DirectoryHT<TypeRepTemplate> AppEnv, bool implicitCast)
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
         return base.Resolve(name, forWrite, AppEnv,implicitCast);
      }
      public override TypeRepTemplate Instantiate(ICollection<TypeRepTemplate> args)
      {
         EnumRepTemplate copy = new EnumRepTemplate(this);
         if (args != null && args.Count != 0) {
           copy.Apply(mkTypeMap(args));
         }
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
   public class DelegateRepTemplate : InterfaceRepTemplate, IEquatable<DelegateRepTemplate>
   {
      private InvokeRepTemplate _invoke = null;
      public InvokeRepTemplate Invoke {
         get {
            return _invoke;
         }
         set {
            _invoke = value;
         }
      }

      public DelegateRepTemplate()
         : base()
      {
      }

      public DelegateRepTemplate(DelegateRepTemplate copyFrom)
         : base(copyFrom)
      {
         if (copyFrom.Invoke != null)
         {
            Invoke = new InvokeRepTemplate(this, copyFrom.Invoke);
         }
      }

      public override ResolveResult Resolve(String name, IList<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv, bool implicitCast)
      {

          if ("Invoke" == name && matchParamsToArgs(Invoke.Params, Invoke.ParamArray, args, AppEnv, implicitCast))
        {     
           ResolveResult res = new ResolveResult();
           res.Result = Invoke;
           res.ResultType = BuildType(Invoke.Return, AppEnv);
           return res;
         }
         return base.Resolve(name, args, AppEnv,implicitCast);
      }

      public override void Apply(Dictionary<string,TypeRepTemplate> args)
      {
         Invoke.Apply(args);
         base.Apply(args);
      }
      public override TypeRepTemplate Instantiate(ICollection<TypeRepTemplate> args)
      {
         DelegateRepTemplate copy = new DelegateRepTemplate(this);
         if (args != null && args.Count != 0) {
           copy.Apply(mkTypeMap(args));
         }
         return copy;
      }

      #region Equality
      public bool Equals (DelegateRepTemplate other)
      {
         if (other == null)
            return false;
			
         return Invoke == other.Invoke && base.Equals(other);
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

         return (Invoke ?? new InvokeRepTemplate()).GetHashCode() ^ hashCode;
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
            Methods.Add(new MethodRepTemplate(this, m));
         }

         foreach (PropRepTemplate p in copyFrom.Properties)
         {
            Properties.Add(new PropRepTemplate(this, p));
         }

         foreach (FieldRepTemplate e in copyFrom.Events)
         {
            Events.Add(new FieldRepTemplate(this, e));
         }

         foreach (IndexerRepTemplate i in copyFrom.Indexers)
         {
            Indexers.Add(new IndexerRepTemplate(this, i));
         }

         if (copyFrom.Iterable != null)
         {
            Iterable = new IterableRepTemplate(this, copyFrom.Iterable);
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
//       public override bool IsA (TypeRepTemplate other,  DirectoryHT<TypeRepTemplate> AppEnv) {
//          InterfaceRepTemplate i = other as InterfaceRepTemplate;
//          if (i == null)
//          {
//             return false;                         
//          }
//          if (i.TypeName == this.TypeName)
//          {
//             return true;
//          }
//          return base.IsA(other,AppEnv);
//       }
// 
      public override ResolveResult Resolve(String name, bool forWrite, DirectoryHT<TypeRepTemplate> AppEnv, bool implicitCast)
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
         return base.Resolve(name, forWrite, AppEnv, implicitCast);
      }

      /// <summary>
      /// Can we match Params + ParamArray against args   
      /// </summary>
      /// 
      protected bool matchParamsToArgs(IList<ParamRepTemplate> param, ParamArrayRepTemplate paramArray, IList<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv, bool implicitCast)
      {
         int argsLength = args == null ? 0 : args.Count;
         int paramsLength = param == null ? 0 : param.Count;
         
         if (paramsLength > 0)
         {
            // Check fixed parameters against args 
            if (argsLength < paramsLength)
            {
               // Length of required fixed Parameters is greater than number of available arguments 
               return false; 
            }
            else
            {
               // Check fixed Parameters against args
               // check that for each argument in the caller its type 'IsA' the type of the formal parameter
               for (int idx = 0; idx < paramsLength; idx++) {
                   if (args[idx] == null || !args[idx].IsA(BuildType(param[idx].Type, AppEnv, new UnknownRepTemplate(param[idx].Type.Type)), AppEnv, implicitCast))
                  {
                     // An argument doesn't match
                     return false; 
                  }
               }
            }
         }

         if (argsLength == paramsLength)
            // OK, fixed args check out.
            return true;

         if (paramArray == null)
            // Extra args and no param array
            return false;

         // We have args left over, check param argument. 

         String paramsTypeStr = paramArray.Type.Type ?? "System.Object";
         if (!paramsTypeStr.EndsWith("[]"))
            // Type should be an array, maybe print a warning if it isn't?
            paramsTypeStr = paramsTypeStr + "[]";

         TypeRepTemplate paramsType = BuildType(paramsTypeStr, AppEnv, new UnknownRepTemplate(paramsTypeStr));

         if (argsLength == paramsLength + 1)
         {
             if (args[argsLength - 1].IsA(paramsType, AppEnv, implicitCast))
             {
                 // Can pass an array as final argument
                 return true;
             }
         }
  
         // Check additional args against params element type
         // Remove final array marker
         paramsTypeStr = paramsTypeStr.Remove(paramsTypeStr.Length-2);
         paramsType = BuildType(paramsTypeStr, AppEnv, new UnknownRepTemplate(paramsTypeStr));

         for (int idx = paramsLength; idx < argsLength; idx++)
         {
            if (args[idx] == null || !args[idx].IsA(paramsType,AppEnv,implicitCast))
               return false;
         }
         return true;
      }

      public override ResolveResult Resolve(String name, IList<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv, bool implicitCast)
      {
         if (Methods != null)
         {
            ResolveResult res = null;
            foreach (MethodRepTemplate m in Methods)
            {
               if (m.Name == name && matchParamsToArgs(m.Params, m.ParamArray, args, AppEnv, implicitCast))
               {
                  res = new ResolveResult();
                  res.Result = m;
                  res.ResultType = BuildType(m.Return, AppEnv);
                  if (!m.IsPartialDefiner)
                     return res;
               }
            }
            if (res != null)
            {
               // We must have only found a partial result, nothing to implement it, so return the partial result 
               return res;
            }

         }
         // Look for a property which holds a delegate with the right type
         if (Properties != null)
         {
            foreach (PropRepTemplate p in Properties)
            {
               if (p.Name == name)
               {
                  // Is p's type a delegate?
                  DelegateRepTemplate del = BuildType(p.Type, AppEnv, null) as DelegateRepTemplate;
                  if (del != null && matchParamsToArgs(del.Invoke.Params, del.Invoke.ParamArray, args, AppEnv,implicitCast))
                  {
                     ResolveResult delRes = new ResolveResult();
                     delRes.Result = del;
                     delRes.ResultType = BuildType(del.Invoke.Return, AppEnv);
                     DelegateResolveResult res = new DelegateResolveResult();
                     res.Result = p;
                     res.ResultType = BuildType(p.Type, AppEnv);
                     res.DelegateResult = delRes;
                     return res;                     
                  }
               }
            }            
         }
         return base.Resolve(name, args, AppEnv,implicitCast);
      }

      public override ResolveResult ResolveIndexer(IList<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv, bool implicitCast)
      {
        
         if (Indexers != null)
         {
            foreach (IndexerRepTemplate i in Indexers)
            {
                if (matchParamsToArgs(i.Params, i.ParamArray, args, AppEnv, implicitCast))
               {
                  ResolveResult res = new ResolveResult();
                  res.Result = i;
                  res.ResultType = BuildType(i.Type, AppEnv);
                  return res;
               }
            }
         }
         return base.ResolveIndexer(args, AppEnv,implicitCast);
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
         if (args != null && args.Count != 0) {
           copy.Apply(mkTypeMap(args));
         }
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
            Constructors.Add(new ConstructorRepTemplate(this, c));
         }

         foreach (FieldRepTemplate f in copyFrom.Fields)
         {
            Fields.Add(new FieldRepTemplate(this, f));
         }

         foreach (MethodRepTemplate u in copyFrom.UnaryOps)
         {
            UnaryOps.Add(new MethodRepTemplate(this, u));
         }

         foreach (MethodRepTemplate b in copyFrom.BinaryOps)
         {
            BinaryOps.Add(new MethodRepTemplate(this, b));
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


      public override ResolveResult Resolve(String name, IList<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv, bool implicitCast)
      {
        
         // Look for a property which holds a delegate with the right type
         if (Fields != null)
         {
            foreach (FieldRepTemplate f in Fields)
            {
               if (f.Name == name)
               {
                  // Is f's type a delegate?
                  DelegateRepTemplate del = BuildType(f.Type, AppEnv, null) as DelegateRepTemplate;
                  if (del != null && matchParamsToArgs(del.Invoke.Params, del.Invoke.ParamArray, args, AppEnv, implicitCast))
                  {
                     ResolveResult delRes = new ResolveResult();
                     delRes.Result = del;
                     delRes.ResultType = BuildType(del.Invoke.Return, AppEnv);
                     DelegateResolveResult res = new DelegateResolveResult();
                     res.Result = f;
                     res.ResultType = BuildType(f.Type, AppEnv);
                     res.DelegateResult = delRes;
                     return res;
                  }
               }
            }            
         }
         return base.Resolve(name, args, AppEnv, implicitCast);
      }

      public override ResolveResult Resolve(String name, bool forWrite, DirectoryHT<TypeRepTemplate> AppEnv,bool implicitCast)
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
         return base.Resolve(name, forWrite, AppEnv,implicitCast);
      }

      public ResolveResult Resolve(IList<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv)
      {
          ResolveResult res = Resolve(args, AppEnv, false);
          if (TemplateUtilities.DO_IMPLICIT_CASTS && res == null) res = Resolve(args, AppEnv, true);
          return res;
      }
      public ResolveResult Resolve(IList<TypeRepTemplate> args, DirectoryHT<TypeRepTemplate> AppEnv, bool implicitCast)
      {
        
         if (Constructors != null)
         {
            foreach (ConstructorRepTemplate c in Constructors)
            {
                if (matchParamsToArgs(c.Params, c.ParamArray, args, AppEnv, implicitCast))
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
         if (args != null && args.Count != 0) {
           copy.Apply(mkTypeMap(args));
         }
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

      public override ResolveResult Resolve(String name, bool forWrite, DirectoryHT<TypeRepTemplate> AppEnv, bool implicitCast)
      {
         return base.Resolve(name, forWrite, AppEnv,implicitCast);
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
         // If we are creating an UnknownRepTemplate for System.Object then don't
         // inherit from ourselves, else we get stack overflow when resolving.
         // This should only happen in the case that we don't have a valid
         // net-templates-dir with a definition for System.Object.
         if (typeName != "System.Object") {
            Inherits = new String[] { "System.Object" };
         } else {
            Inherits = new String[] { };
         }
      }

      public UnknownRepTemplate (TypeRepRef typeName) : this(typeName.Type)
      {
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
         Inherits = new String[] { "System.Object" };
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
		
      public override bool IsA (TypeRepTemplate other,  DirectoryHT<TypeRepTemplate> AppEnv, bool implicitCast) {
         return base.IsA(other, AppEnv,implicitCast);                         
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

   // Used when the result of resolving the callee of an APPLY node is a pointer to a delegate
   public class DelegateResolveResult : ResolveResult
   {
      public ResolveResult DelegateResult
      {
         get; set;
      }
   }

}
