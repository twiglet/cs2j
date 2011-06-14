namespace Tester.MiscSyntax
{

    // An abstract property
    
    /// <summary>
    /// A block of data in a packet. Packets are composed of one or more blocks,
    /// each block containing one or more fields
    /// </summary>
    public abstract class PacketBlock
    {
        /// <summary>Current length of the data in this packet</summary>
        public abstract int Length { get; }

        /// <summary>
        /// Create a block from a byte array
        /// </summary>
        /// <param name="bytes">Byte array containing the serialized block</param>
        /// <param name="i">Starting position of the block in the byte array.
        /// This will point to the data after the end of the block when the
        /// call returns</param>
        public abstract void FromBytes(byte[] bytes, ref int i);

        /// <summary>
        /// Serialize this block into a byte array
        /// </summary>
        /// <param name="bytes">Byte array to serialize this block into</param>
        /// <param name="i">Starting position in the byte array to serialize to.
        /// This will point to the position directly after the end of the
        /// serialized block when the call returns</param>
        public abstract void ToBytes(byte[] bytes, ref int i);
    }

}