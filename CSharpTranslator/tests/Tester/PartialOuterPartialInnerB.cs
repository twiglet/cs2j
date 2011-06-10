using System;
namespace Tester
{
	// ordinary outer class
	public partial class PartialOuterPartialInner
	{

		public partial class PartialMiddle {
			// First part of inner
			public partial class PartialInner {
				
				// member ab
				public int ab = 0;
			}
			
			// middlea member
			public int middleab = 0;
		
		}
		
		// b outer member
		public int outerb = 0;
			

		public partial class PartialMiddle {
			
			// middle b member	
			public int middlebb = 0;

			// Second part of inner
			public partial class PartialInner {
				// member b
				public int bb = 0;
			}
		}
	}
}

