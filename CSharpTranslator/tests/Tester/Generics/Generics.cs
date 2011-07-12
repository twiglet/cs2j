using System;

namespace Tester.Generics
{

    class Factory6<U> where U : new() {
        public static U GetNew() { return new U(); }
    }
    class Program6 {
        static void Main6(){
            int i = Factory6<int>.GetNew();
            object obj = Factory6<object>.GetNew();
            // Here, 'i' is equal to 0 and 'obj' references
            // an instance of the class 'object'.
        }
    }
    
    // Derivation constraint
    
    // If you wish to use certain members of the instances of a parameter type in a generic, you must apply a derivation constraint. Here is an example which illustrates the syntax:
    // 
    // 
    // Example 7
    
    interface ICustomInterface7 { int Fct(); }
    class C7<U> where U : ICustomInterface7 {
        public int AnotherFct(U u) { return u.Fct(); }
    }
    
    // You can apply several interface implementation constraints and one base class inheritance constraint on a same type parameter. In this case, the base class must appear in the list of types. You can also use this constraint conjointly with the default constructor constraint. In this case, the default constructor constraint must appear last:
    // 
    // 
    // Example 8
    
    interface ICustomInterface18 { int Fct1(); }
    interface ICustomInterface28 { string Fct2(); }
    class BaseClass8{}
    class C8<U>
        where U : BaseClass8, ICustomInterface18, ICustomInterface28, new() {
        public string Fct(U u) { return u.Fct2(); }
    }
    
    // You cannot use a sealed class or a one of the System.Object, System.Array, System.Delegate, System.Enum or System.ValueType class as the base class of a type parameter.
    // 
    // 
    // You also cannot use the static members of T like this:
    // 
    // 
    // Example 9
    
    class BaseClass9 { public static void Fct(){} }
    class C9<T> where T : BaseClass9 {
        void F(){
            /* commented out to build
            // Compilation Error: 'T' is a 'type parameter',
            // which is not valid in the given context.
            T.Fct();
             */
            // Here is the right syntax to call Fct().
            BaseClass9.Fct();
        }
    }
    
    // A type used in a derivation constraint can be an open or closed generic type. Let's illustrate this using the System.IComparable<T> interface. Remember that the types which implement this interface can see their instances compared to an instance of type T.
    // 
    // 
    // Example 10
    
    class C1A<U> where U : IComparable<int> {
        public int Compare( U u, int i ) { return u.CompareTo( i ); }
    }
    class C2A<U> where U : IComparable<U> {
        public int Compare( U u1, U u2 ) { return u1.CompareTo( u2 ); }
    }
    class C3A<U,V> where U : IComparable<V> {
        public int Compare( U u, V v ) { return u.CompareTo( v ); }
    }
    class C4A<U,V> where U : IComparable<V>, IComparable<int> {
        public int Compare( U u, int i ) { return u.CompareTo( i ); }
    }
    
    // Note that a type used in a derivation constraint must have a visibility greater or equal to the one of the generic type which contains this parameter type. For example:
    // 
    // 
    // Example 11

    /* commented out to build
    internal class BaseClassB{}
    // Compilation Error: Inconsistent accessibility:
    // constraint type 'BaseClass' is less accessible than 'C<T>'
    public class CB<T> where T : BaseClassB{}
    */
    // To be used in a generic type, certain functionalities can force you to impose certain derivation constraints. For example, if you wish to use a T type parameter in a catch clause, you must constrain T to derive from System.Exception or of one of its derived classes. Also, if you wish to use the using keyword to automatically dispose of an instance of the type parameter, it must be constraint to use the System.IDisposable interface. Finally, if you wish to use the foreach keyword to enumerate the elements of an instance of the parameter type, it must be constraint to implement the System.Collections.IEnumerable or System.Collections.Generic.IEnumerable<T> interface.
    // 
    // 
    // Take note that in the special case where T is constrained to implement an interface and T is a value type, the call to a member of the interface on an instance of T will not cause a boxing operation. The following example puts this into evidence:
    // 
    // 
    // Example 12
    // 
    interface ICounterC{
        void Increment();
        int Val{get;}
    }
    struct CounterC : ICounterC {
        private int i;
        public void Increment() { i++; }
        public int Val { get { return i; } }
    }
    class CC<T> where T : ICounterC, new() {
        public void Fct(){
            T t = new T();
            System.Console.WriteLine( t.Val.ToString() );
            t.Increment();    // Modify the state of 't'.
            System.Console.WriteLine( t.Val.ToString() );
            
            // Modify the state of a boxed copy of 't'.
            (t as ICounterC).Increment();
            System.Console.WriteLine( t.Val.ToString() );
        }
    }
    class ProgramC {
        static void CMain() {
            /* commented out to build 
             CC<Counter> c = new CC<CounterC>();
            c.Fct();
             */
        }
    }
}