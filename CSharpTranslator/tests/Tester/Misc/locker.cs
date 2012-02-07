using System;

// Test translation for lock statements

namespace Tester.Locker
{
class B {
       public virtual void foo() {
           lock(this)
               Console.WriteLine("summat");
       }
}
class D : B {
       public new void foo() {
           lock (new String[5])
           {
               Console.WriteLine("and");
               Console.WriteLine("nuttin");
           }
       }
}

public class Test5 {
       public static void T5Main(){
               B b = new D();
               b.foo();
               Console.WriteLine("Done");
       }
}

}
